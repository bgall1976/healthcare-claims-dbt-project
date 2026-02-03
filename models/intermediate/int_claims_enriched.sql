{{
    config(
        materialized='ephemeral'
    )
}}

with claims as (
    select * from {{ ref('stg_claims') }}
),

diagnoses as (
    select * from {{ ref('stg_diagnoses') }}
),

procedures as (
    select * from {{ ref('stg_procedures') }}
),

enriched as (
    select
        -- Claim identifiers
        c.claim_line_id,
        c.claim_id,
        c.line_number,
        c.patient_id,
        c.provider_npi,
        
        -- Diagnosis info
        c.diagnosis_code,
        d.diagnosis_description,
        d.diagnosis_category,
        d.icd_chapter,
        d.is_chronic_condition,
        
        -- Procedure info
        c.procedure_code,
        p.procedure_description,
        p.procedure_category,
        p.is_surgical,
        p.rvu_total,
        
        -- Service details
        c.place_of_service,
        c.service_date,
        c.paid_date,
        c.units,
        c.claim_status,
        
        -- Calculate days to payment
        {{ dbt.datediff('c.service_date', 'c.paid_date', 'day') }} as days_to_payment,
        
        -- Amounts (keep in cents)
        c.billed_amount_cents,
        c.allowed_amount_cents,
        c.paid_amount_cents,
        c.patient_responsibility_cents,
        
        -- Calculate payment rate
        case 
            when c.billed_amount_cents > 0 
            then round(cast(c.paid_amount_cents as decimal(18,4)) / c.billed_amount_cents * 100, 2)
            else 0 
        end as payment_rate_pct
        
    from claims c
    left join diagnoses d on c.diagnosis_code = d.diagnosis_code
    left join procedures p on c.procedure_code = p.procedure_code
)

select * from enriched
