{% snapshot patient_snapshot %}

{{
    config(
        target_schema='snapshots',
        strategy='check',
        unique_key='patient_id',
        check_cols=['address_line_1', 'city', 'state', 'zip_code', 'plan_type', 'plan_name'],
        invalidate_hard_deletes=True
    )
}}

/*
    SCD Type 2 Snapshot for Patient Dimension
    
    Tracks changes to:
    - Address (address_line_1, city, state, zip_code)
    - Insurance plan (plan_type, plan_name)
    
    Strategy: 'check' - creates new record when any check_cols value changes
    
    Resulting columns added by dbt:
    - dbt_scd_id: Unique identifier for the snapshot record
    - dbt_updated_at: Timestamp when the snapshot was taken
    - dbt_valid_from: When this version became effective
    - dbt_valid_to: When this version was superseded (NULL if current)
*/

select
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    address_line_1,
    city,
    state,
    zip_code,
    plan_type,
    plan_name,
    member_id,
    coverage_effective_date,
    coverage_term_date,
    source_updated_at
from {{ ref('stg_patients') }}

{% endsnapshot %}
