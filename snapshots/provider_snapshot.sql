{% snapshot provider_snapshot %}

{{
    config(
        target_schema='snapshots',
        strategy='check',
        unique_key='npi',
        check_cols=['practice_name', 'address_line_1', 'city', 'state', 'zip_code', 'is_accepting_new_patients'],
        invalidate_hard_deletes=True
    )
}}

/*
    SCD Type 2 Snapshot for Provider Dimension
    
    Tracks changes to:
    - Practice information (practice_name, address)
    - Patient acceptance status
    
    Use cases:
    - Track when providers changed practices
    - Audit provider network changes over time
    - Historical analysis of provider availability
*/

select
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
    source_updated_at
from {{ ref('int_provider_details') }}

{% endsnapshot %}
