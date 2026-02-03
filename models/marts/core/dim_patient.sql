{{
    config(
        materialized='table',
        tags=['core', 'dimension', 'scd2']
    )
}}

{# 
    This dimension implements SCD Type 2 using dbt snapshots.
    If snapshots haven't been run yet, we fall back to current data.
    In production, the snapshot would be the source of truth.
#}

{% set snapshot_exists = adapter.get_relation(
    database=this.database,
    schema='snapshots',
    identifier='patient_snapshot'
) %}

{% if snapshot_exists %}

-- Use snapshot data when available (full SCD Type 2)
with snapshot_data as (
    select * from {{ ref('patient_snapshot') }}
),

final as (
    select
        -- Surrogate key (hash of natural key + valid_from for uniqueness)
        {{ dbt_utils.generate_surrogate_key(['patient_id', 'dbt_valid_from']) }} as patient_key,
        
        -- Natural key
        patient_id,
        
        -- Demographics
        first_name,
        last_name,
        first_name || ' ' || last_name as patient_full_name,
        date_of_birth,
        gender,
        
        -- Address (tracked for SCD)
        address_line_1,
        city,
        state,
        zip_code,
        
        -- Insurance (tracked for SCD)
        plan_type,
        plan_name,
        member_id,
        
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

-- Fallback to current data only (before snapshots are run)
with current_data as (
    select * from {{ ref('int_patient_demographics') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['patient_id']) }} as patient_key,
        patient_id,
        first_name,
        last_name,
        patient_full_name,
        date_of_birth,
        gender,
        address_line_1,
        city,
        state,
        zip_code,
        plan_type,
        plan_name,
        member_id,
        cast('1900-01-01' as timestamp) as valid_from,
        cast(null as timestamp) as valid_to,
        true as is_current,
        cast(null as varchar) as scd_id,
        source_updated_at as dbt_updated_at
    from current_data
)

{% endif %}

select * from final
