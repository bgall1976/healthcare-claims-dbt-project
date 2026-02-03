{{
    config(
        materialized='table',
        tags=['features', 'ml']
    )
}}

{#
    Patient Risk Profile - ML Feature Store Table
    
    This model creates point-in-time correct features for ML models.
    Features are calculated as of a specific date to prevent data leakage.
    
    Grain: One row per patient
#}

with claims as (
    select * from {{ ref('fact_claims') }}
),

patients as (
    select * from {{ ref('dim_patient') }}
    where is_current = true
),

diagnoses as (
    select * from {{ ref('dim_diagnosis') }}
),

-- Aggregate claims by patient
patient_claims as (
    select
        c.patient_key,
        
        -- Utilization metrics
        count(distinct c.claim_id) as total_claims,
        count(c.claim_line_id) as total_claim_lines,
        
        -- Time-based utilization (last 12 months)
        count(distinct case 
            when c.service_date >= current_date - interval '12 months' 
            then c.claim_id 
        end) as claims_12m,
        
        count(distinct case 
            when c.service_date >= current_date - interval '6 months' 
            then c.claim_id 
        end) as claims_6m,
        
        -- Cost metrics
        sum(c.paid_amount) as total_paid_all_time,
        sum(case 
            when c.service_date >= current_date - interval '12 months' 
            then c.paid_amount else 0 
        end) as total_paid_12m,
        
        avg(c.paid_amount) as avg_paid_per_line,
        max(c.paid_amount) as max_paid_single_line,
        
        -- Service patterns
        count(distinct c.service_date) as distinct_service_dates,
        min(c.service_date) as first_claim_date,
        max(c.service_date) as last_claim_date,
        
        -- Provider diversity
        count(distinct c.provider_key) as distinct_providers,
        
        -- Procedure metrics
        sum(case when c.is_surgical then 1 else 0 end) as surgical_procedure_count,
        
        -- Chronic condition flags from diagnoses
        count(distinct case when c.is_chronic_condition then c.diagnosis_code end) as chronic_condition_count
        
    from claims c
    group by c.patient_key
),

-- Get distinct chronic conditions per patient
patient_chronic_conditions as (
    select
        c.patient_key,
        listagg(distinct d.diagnosis_category, ', ') as chronic_conditions_list
    from claims c
    join diagnoses d on c.diagnosis_key = d.diagnosis_key
    where d.is_chronic_condition = true
    group by c.patient_key
),

final as (
    select
        -- Identifiers
        p.patient_id,
        p.patient_key,
        
        -- Demographics (for segmentation)
        p.gender,
        p.state,
        p.zip_code,
        p.plan_type,
        
        -- Utilization features
        coalesce(pc.total_claims, 0) as total_claims,
        coalesce(pc.total_claim_lines, 0) as total_claim_lines,
        coalesce(pc.claims_12m, 0) as total_claims_12m,
        coalesce(pc.claims_6m, 0) as total_claims_6m,
        coalesce(pc.distinct_service_dates, 0) as distinct_visit_days,
        coalesce(pc.distinct_providers, 0) as distinct_providers,
        
        -- Cost features
        coalesce(pc.total_paid_all_time, 0) as total_paid_all_time,
        coalesce(pc.total_paid_12m, 0) as total_paid_12m,
        coalesce(pc.avg_paid_per_line, 0) as avg_cost_per_service,
        coalesce(pc.max_paid_single_line, 0) as max_single_service_cost,
        
        -- Risk indicators
        coalesce(pc.chronic_condition_count, 0) as chronic_condition_count,
        coalesce(pc.surgical_procedure_count, 0) as surgical_procedure_count,
        pcc.chronic_conditions_list,
        
        -- Engagement metrics
        pc.first_claim_date,
        pc.last_claim_date,
        {{ dbt.datediff('pc.first_claim_date', 'pc.last_claim_date', 'day') }} as days_from_first_to_last_claim,
        
        -- Derived risk flags
        case when coalesce(pc.chronic_condition_count, 0) >= 2 then true else false end as has_multiple_chronic_conditions,
        case when coalesce(pc.claims_12m, 0) >= 12 then true else false end as is_high_utilizer,
        case when coalesce(pc.total_paid_12m, 0) >= 10000 then true else false end as is_high_cost,
        
        -- Feature generation timestamp
        current_timestamp as feature_generated_at
        
    from patients p
    left join patient_claims pc on p.patient_key = pc.patient_key
    left join patient_chronic_conditions pcc on p.patient_key = pcc.patient_key
)

select * from final
