{{
    config(
        materialized='ephemeral'
    )
}}

with providers as (
    select * from {{ ref('stg_providers') }}
),

with_derived as (
    select
        npi,
        provider_first_name,
        provider_last_name,
        provider_full_name,
        credential,
        specialty,
        
        -- Specialty grouping
        case
            when specialty in ('Internal Medicine', 'Family Medicine') then 'Primary Care'
            when specialty in ('Cardiology', 'Neurology', 'Gastroenterology', 'Pulmonology') then 'Medical Specialty'
            when specialty in ('Orthopedics') then 'Surgical Specialty'
            when specialty in ('Psychiatry') then 'Behavioral Health'
            when specialty in ('Dermatology') then 'Other Specialty'
            else 'Other'
        end as specialty_category,
        
        -- Practice info
        practice_name,
        address_line_1,
        city,
        state,
        zip_code,
        left(zip_code, 3) as zip3,
        phone,
        
        is_accepting_new_patients,
        source_updated_at
        
    from providers
)

select * from with_derived
