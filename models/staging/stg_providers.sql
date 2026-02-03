{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'raw_providers') }}
),

-- Get most recent record per provider NPI
deduplicated as (
    select
        *,
        row_number() over (
            partition by npi 
            order by updated_at desc
        ) as row_num
    from source
),

most_recent as (
    select * from deduplicated where row_num = 1
),

renamed as (
    select
        -- Primary key
        npi,
        
        -- Provider info
        trim(provider_first_name) as provider_first_name,
        trim(provider_last_name) as provider_last_name,
        trim(provider_first_name) || ' ' || trim(provider_last_name) as provider_full_name,
        upper(trim(credential)) as credential,
        trim(specialty) as specialty,
        
        -- Practice info
        trim(practice_name) as practice_name,
        trim(address_line_1) as address_line_1,
        trim(city) as city,
        upper(trim(state)) as state,
        trim(zip_code) as zip_code,
        trim(phone) as phone,
        
        -- Status
        case 
            when lower(accepting_new_patients) in ('true', '1', 'yes') then true
            else false
        end as is_accepting_new_patients,
        
        -- Metadata
        cast(updated_at as timestamp) as source_updated_at
        
    from most_recent
)

select * from renamed
