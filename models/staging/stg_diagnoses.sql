{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('reference', 'ref_icd10_codes') }}
),

renamed as (
    select
        -- Primary key
        upper(trim(icd10_code)) as diagnosis_code,
        
        -- Attributes
        trim(description) as diagnosis_description,
        trim(category) as diagnosis_category,
        trim(chapter) as icd_chapter,
        
        -- Flags
        case 
            when lower(is_chronic) in ('true', '1', 'yes') then true
            else false
        end as is_chronic_condition
        
    from source
)

select * from renamed
