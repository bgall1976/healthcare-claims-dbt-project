{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'raw_claims') }}
),

renamed as (
    select
        -- Primary key
        claim_id || '-' || cast(line_number as varchar) as claim_line_id,
        
        -- Identifiers
        claim_id,
        line_number,
        patient_id,
        provider_npi,
        
        -- Codes
        upper(trim(diagnosis_code)) as diagnosis_code,
        upper(trim(procedure_code)) as procedure_code,
        place_of_service,
        
        -- Dates
        cast(service_date as date) as service_date,
        cast(paid_date as date) as paid_date,
        
        -- Amounts (convert to cents for precision)
        cast(billed_amount * 100 as integer) as billed_amount_cents,
        cast(allowed_amount * 100 as integer) as allowed_amount_cents,
        cast(paid_amount * 100 as integer) as paid_amount_cents,
        cast(patient_responsibility * 100 as integer) as patient_responsibility_cents,
        
        -- Quantities
        units,
        
        -- Status
        upper(claim_status) as claim_status
        
    from source
    where claim_id is not null
)

select * from renamed
