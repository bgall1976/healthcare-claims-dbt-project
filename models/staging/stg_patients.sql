{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'raw_patients') }}
),

-- Get the most recent record per patient for the staging layer
-- Full history is maintained in the snapshot
deduplicated as (
    select
        *,
        row_number() over (
            partition by patient_id 
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
        patient_id,
        
        -- Demographics
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        cast(date_of_birth as date) as date_of_birth,
        upper(trim(gender)) as gender,
        
        -- Address
        trim(address_line_1) as address_line_1,
        trim(city) as city,
        upper(trim(state)) as state,
        trim(zip_code) as zip_code,
        
        -- Insurance info
        upper(trim(plan_type)) as plan_type,
        trim(plan_name) as plan_name,
        member_id,
        
        -- Coverage dates
        cast(effective_date as date) as coverage_effective_date,
        cast(term_date as date) as coverage_term_date,
        
        -- Metadata
        cast(updated_at as timestamp) as source_updated_at
        
    from most_recent
)

select * from renamed
