{{
    config(
        materialized='table',
        tags=['features', 'analytics']
    )
}}

{#
    Utilization Summary
    
    Time-series aggregation of healthcare utilization.
    Useful for:
    - Trend analysis dashboards
    - Seasonal pattern detection
    - Executive reporting
    
    Grain: Year-Month x Specialty Category
#}

with claims as (
    select * from {{ ref('fact_claims') }}
),

providers as (
    select * from {{ ref('dim_provider') }}
    where is_current = true
),

dates as (
    select * from {{ ref('dim_date') }}
),

-- Aggregate by month and specialty
monthly_specialty_agg as (
    select
        d.year,
        d.month,
        d.year_month,
        p.specialty_category,
        
        -- Volume metrics
        count(distinct c.claim_id) as claim_count,
        count(c.claim_line_id) as claim_line_count,
        count(distinct c.patient_key) as unique_patients,
        count(distinct c.provider_key) as active_providers,
        
        -- Financial metrics
        sum(c.billed_amount) as total_billed,
        sum(c.allowed_amount) as total_allowed,
        sum(c.paid_amount) as total_paid,
        sum(c.patient_responsibility) as total_patient_responsibility,
        
        -- Averages
        avg(c.paid_amount) as avg_paid_per_line,
        avg(c.billed_amount) as avg_billed_per_line,
        
        -- Service type breakdown
        sum(case when c.is_surgical then 1 else 0 end) as surgical_count,
        sum(case when c.is_chronic_condition then 1 else 0 end) as chronic_visit_count
        
    from claims c
    join dates d on c.service_date = d.full_date
    join providers p on c.provider_key = p.provider_key
    group by d.year, d.month, d.year_month, p.specialty_category
),

-- Add month-over-month calculations
with_mom as (
    select
        *,
        
        -- Previous month values (for MoM comparison)
        lag(claim_count) over (
            partition by specialty_category 
            order by year, month
        ) as prev_month_claims,
        
        lag(total_paid) over (
            partition by specialty_category 
            order by year, month
        ) as prev_month_paid,
        
        lag(unique_patients) over (
            partition by specialty_category 
            order by year, month
        ) as prev_month_patients
        
    from monthly_specialty_agg
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['year_month', 'specialty_category']) }} as summary_key,
        
        -- Dimensions
        year,
        month,
        year_month,
        specialty_category,
        
        -- Volume metrics
        claim_count,
        claim_line_count,
        unique_patients,
        active_providers,
        
        -- Financial metrics
        total_billed,
        total_allowed,
        total_paid,
        total_patient_responsibility,
        
        -- Per-unit metrics
        avg_paid_per_line,
        avg_billed_per_line,
        round(total_paid / nullif(unique_patients, 0), 2) as paid_per_patient,
        round(claim_count / nullif(unique_patients, 0), 2) as claims_per_patient,
        
        -- Service mix
        surgical_count,
        chronic_visit_count,
        round(surgical_count * 100.0 / nullif(claim_line_count, 0), 2) as surgical_pct,
        round(chronic_visit_count * 100.0 / nullif(claim_line_count, 0), 2) as chronic_pct,
        
        -- Month-over-month changes
        prev_month_claims,
        claim_count - coalesce(prev_month_claims, 0) as claims_mom_change,
        round((claim_count - coalesce(prev_month_claims, claim_count)) * 100.0 / nullif(prev_month_claims, 0), 2) as claims_mom_pct,
        
        prev_month_paid,
        total_paid - coalesce(prev_month_paid, 0) as paid_mom_change,
        round((total_paid - coalesce(prev_month_paid, total_paid)) * 100.0 / nullif(prev_month_paid, 0), 2) as paid_mom_pct,
        
        -- Metadata
        current_timestamp as generated_at
        
    from with_mom
)

select * from final
order by year_month, specialty_category
