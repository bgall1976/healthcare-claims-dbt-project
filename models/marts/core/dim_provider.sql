{{
    config(
        materialized='table',
        tags=['core', 'dimension', 'scd2']
    )
}}

{# 
    Provider dimension with SCD Type 2 for tracking practice changes.
    Tracks: practice_name, address, accepting_new_patients status
#}

{% set snapshot_exists = adapter.get_relation(
    database=this.database,
    schema='snapshots',
    identifier='provider_snapshot'
) %}

{% if snapshot_exists %}

with snapshot_data as (
    select * from {{ ref('provider_snapshot') }}
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['npi', 'dbt_valid_from']) }} as provider_key,
        
        -- Natural key
        npi,
        
        -- Provider info
        provider_first_name,
        provider_last_name,
        provider_full_name,
        credential,
        specialty,
        specialty_category,
        
        -- Practice info (tracked for SCD)
        practice_name,
        address_line_1,
        city,
        state,
        zip_code,
        phone,
        
        is_accepting_new_patients,
        
        -- SCD Type 2 metadata
        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,
        case when dbt_valid_to is null then true else false end as is_current,
        
        -- Audit
        dbt_scd_id as scd_id,
        dbt_updated_at as dbt_updated_at
        
    from snapshot_data
)

{% else %}

-- Fallback before snapshots exist
with current_data as (
    select * from {{ ref('int_provider_details') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['npi']) }} as provider_key,
        npi,
        provider_first_name,
        provider_last_name,
        provider_full_name,
        credential,
        specialty,
        specialty_category,
        practice_name,
        address_line_1,
        city,
        state,
        zip_code,
        phone,
        is_accepting_new_patients,
        cast('1900-01-01' as timestamp) as valid_from,
        cast(null as timestamp) as valid_to,
        true as is_current,
        cast(null as varchar) as scd_id,
        source_updated_at as dbt_updated_at
    from current_data
)

{% endif %}

select * from final
