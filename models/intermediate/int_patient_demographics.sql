{{
    config(
        materialized='ephemeral'
    )
}}

with patients as (
    select * from {{ ref('stg_patients') }}
),

with_age as (
    select
        patient_id,
        first_name,
        last_name,
        first_name || ' ' || last_name as patient_full_name,
        date_of_birth,
        gender,
        
        -- Calculate age
        {{ dbt.datediff('date_of_birth', dbt.current_timestamp(), 'year') }} as age_years,
        
        -- Age grouping for analytics
        case 
            when {{ dbt.datediff('date_of_birth', dbt.current_timestamp(), 'year') }} < 18 then 'Pediatric (0-17)'
            when {{ dbt.datediff('date_of_birth', dbt.current_timestamp(), 'year') }} between 18 and 34 then 'Young Adult (18-34)'
            when {{ dbt.datediff('date_of_birth', dbt.current_timestamp(), 'year') }} between 35 and 49 then 'Adult (35-49)'
            when {{ dbt.datediff('date_of_birth', dbt.current_timestamp(), 'year') }} between 50 and 64 then 'Mature Adult (50-64)'
            when {{ dbt.datediff('date_of_birth', dbt.current_timestamp(), 'year') }} >= 65 then 'Senior (65+)'
            else 'Unknown'
        end as age_group,
        
        -- Address
        address_line_1,
        city,
        state,
        zip_code,
        left(zip_code, 3) as zip3,  -- For regional analysis
        
        -- Insurance
        plan_type,
        plan_name,
        member_id,
        coverage_effective_date,
        coverage_term_date,
        
        -- Coverage status
        case 
            when coverage_term_date is null then true
            when coverage_term_date > current_date then true
            else false
        end as is_currently_covered,
        
        source_updated_at
        
    from patients
)

select * from with_age
