{{
    config(
        materialized='table',
        tags=['features', 'ml', 'quality']
    )
}}

{#
    Provider Quality Metrics
    
    Calculates quality and efficiency metrics for providers.
    Useful for:
    - Network adequacy analysis
    - Value-based care programs
    - Provider performance dashboards
    
    Grain: One row per provider (NPI)
#}

with claims as (
    select * from {{ ref('fact_claims') }}
),

providers as (
    select * from {{ ref('dim_provider') }}
    where is_current = true
),

-- Aggregate claims by provider
provider_claims as (
    select
        c.provider_key,
        
        -- Volume metrics
        count(distinct c.claim_id) as total_claims,
        count(c.claim_line_id) as total_claim_lines,
        count(distinct c.patient_key) as total_patients_served,
        
        -- Cost metrics
        sum(c.billed_amount) as total_billed,
        sum(c.allowed_amount) as total_allowed,
        sum(c.paid_amount) as total_paid,
        
        avg(c.billed_amount) as avg_billed_per_line,
        avg(c.paid_amount) as avg_paid_per_line,
        
        -- Efficiency metrics
        avg(c.payment_rate_pct) as avg_payment_rate_pct,
        avg(c.days_to_payment) as avg_days_to_payment,
        
        -- Service mix
        count(distinct c.procedure_code) as distinct_procedures,
        count(distinct c.diagnosis_code) as distinct_diagnoses,
        
        -- Procedure complexity
        sum(case when c.is_surgical then 1 else 0 end) as surgical_procedures,
        sum(case when c.is_chronic_condition then 1 else 0 end) as chronic_condition_visits,
        
        -- Time patterns
        min(c.service_date) as first_service_date,
        max(c.service_date) as last_service_date,
        count(distinct c.service_date) as distinct_service_days
        
    from claims c
    group by c.provider_key
),

-- Calculate percentile ranks for benchmarking
provider_rankings as (
    select
        provider_key,
        total_claims,
        total_paid,
        avg_paid_per_line,
        
        -- Percentile rankings (0-100)
        percent_rank() over (order by total_claims) * 100 as volume_percentile,
        percent_rank() over (order by avg_paid_per_line) * 100 as cost_percentile,
        percent_rank() over (order by total_patients_served) * 100 as patient_reach_percentile
        
    from provider_claims
),

final as (
    select
        -- Identifiers
        p.npi,
        p.provider_key,
        p.provider_full_name,
        p.credential,
        p.specialty,
        p.specialty_category,
        
        -- Practice info
        p.practice_name,
        p.city,
        p.state,
        p.is_accepting_new_patients,
        
        -- Volume metrics
        coalesce(pc.total_claims, 0) as total_claims,
        coalesce(pc.total_claim_lines, 0) as total_claim_lines,
        coalesce(pc.total_patients_served, 0) as total_patients_served,
        coalesce(pc.distinct_service_days, 0) as active_days,
        
        -- Financial metrics
        coalesce(pc.total_billed, 0) as total_billed,
        coalesce(pc.total_allowed, 0) as total_allowed,
        coalesce(pc.total_paid, 0) as total_paid,
        coalesce(pc.avg_billed_per_line, 0) as avg_billed_per_service,
        coalesce(pc.avg_paid_per_line, 0) as avg_cost_per_service,
        
        -- Efficiency metrics
        coalesce(pc.avg_payment_rate_pct, 0) as avg_payment_rate_pct,
        coalesce(pc.avg_days_to_payment, 0) as avg_days_to_payment,
        
        -- Service diversity
        coalesce(pc.distinct_procedures, 0) as distinct_procedures_offered,
        coalesce(pc.distinct_diagnoses, 0) as distinct_conditions_treated,
        
        -- Case mix indicators
        coalesce(pc.surgical_procedures, 0) as surgical_procedure_count,
        round(coalesce(pc.surgical_procedures, 0) * 100.0 / nullif(pc.total_claim_lines, 0), 2) as surgical_rate_pct,
        coalesce(pc.chronic_condition_visits, 0) as chronic_condition_visits,
        round(coalesce(pc.chronic_condition_visits, 0) * 100.0 / nullif(pc.total_claim_lines, 0), 2) as chronic_care_rate_pct,
        
        -- Benchmarking percentiles
        round(coalesce(pr.volume_percentile, 0), 1) as volume_percentile,
        round(coalesce(pr.cost_percentile, 0), 1) as cost_percentile,
        round(coalesce(pr.patient_reach_percentile, 0), 1) as patient_reach_percentile,
        
        -- Tenure
        pc.first_service_date,
        pc.last_service_date,
        {{ dbt.datediff('pc.first_service_date', 'current_date', 'day') }} as days_since_first_service,
        
        -- Quality tier (derived)
        case
            when pr.cost_percentile <= 33 and pr.volume_percentile >= 50 then 'High Value'
            when pr.cost_percentile >= 67 and pr.volume_percentile >= 50 then 'High Cost'
            when pr.volume_percentile < 25 then 'Low Volume'
            else 'Standard'
        end as value_tier,
        
        -- Metadata
        current_timestamp as feature_generated_at
        
    from providers p
    left join provider_claims pc on p.provider_key = pc.provider_key
    left join provider_rankings pr on p.provider_key = pr.provider_key
)

select * from final
