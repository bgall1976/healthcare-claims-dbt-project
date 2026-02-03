{{
    config(
        materialized='table',
        tags=['core', 'fact']
    )
}}

{#
    Fact table at the claim line grain.
    All amounts stored in dollars (converted from cents in staging).
    Foreign keys link to current dimension records by default.
#}

with claims as (
    select * from {{ ref('int_claims_enriched') }}
),

dim_patient as (
    select patient_key, patient_id 
    from {{ ref('dim_patient') }}
    where is_current = true
),

dim_provider as (
    select provider_key, npi 
    from {{ ref('dim_provider') }}
    where is_current = true
),

dim_procedure as (
    select procedure_key, procedure_code 
    from {{ ref('dim_procedure') }}
),

dim_diagnosis as (
    select diagnosis_key, diagnosis_code 
    from {{ ref('dim_diagnosis') }}
),

dim_date as (
    select date_key, full_date 
    from {{ ref('dim_date') }}
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['c.claim_line_id']) }} as claim_key,
        
        -- Natural key
        c.claim_line_id,
        c.claim_id,
        c.line_number,
        
        -- Dimension foreign keys
        coalesce(dp.patient_key, {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }}) as patient_key,
        coalesce(dpr.provider_key, {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }}) as provider_key,
        coalesce(dproc.procedure_key, {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }}) as procedure_key,
        coalesce(ddiag.diagnosis_key, {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }}) as diagnosis_key,
        coalesce(dd_service.date_key, '19000101') as service_date_key,
        coalesce(dd_paid.date_key, '19000101') as paid_date_key,
        
        -- Degenerate dimensions (codes kept for convenience)
        c.diagnosis_code,
        c.procedure_code,
        c.place_of_service,
        c.claim_status,
        
        -- Date values (for easier querying)
        c.service_date,
        c.paid_date,
        
        -- Measures (convert cents to dollars)
        {{ cents_to_dollars('c.billed_amount_cents') }} as billed_amount,
        {{ cents_to_dollars('c.allowed_amount_cents') }} as allowed_amount,
        {{ cents_to_dollars('c.paid_amount_cents') }} as paid_amount,
        {{ cents_to_dollars('c.patient_responsibility_cents') }} as patient_responsibility,
        
        -- Pre-calculated metrics
        c.units,
        c.days_to_payment,
        c.payment_rate_pct,
        
        -- Derived flags
        c.is_chronic_condition,
        c.is_surgical,
        
        -- Metadata
        current_timestamp as dbt_loaded_at
        
    from claims c
    
    -- Join to dimensions (current records only)
    left join dim_patient dp on c.patient_id = dp.patient_id
    left join dim_provider dpr on c.provider_npi = dpr.npi
    left join dim_procedure dproc on c.procedure_code = dproc.procedure_code
    left join dim_diagnosis ddiag on c.diagnosis_code = ddiag.diagnosis_code
    left join dim_date dd_service on c.service_date = dd_service.full_date
    left join dim_date dd_paid on c.paid_date = dd_paid.full_date
)

select * from final
