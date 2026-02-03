{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('reference', 'ref_cpt_codes') }}
),

renamed as (
    select
        -- Primary key
        upper(trim(cpt_code)) as procedure_code,
        
        -- Attributes
        trim(description) as procedure_description,
        trim(category) as procedure_category,
        
        -- Flags
        case 
            when lower(is_surgical) in ('true', '1', 'yes') then true
            else false
        end as is_surgical,
        
        -- RVU components (for cost analysis)
        cast(rvu_work as decimal(10,4)) as rvu_work,
        cast(rvu_facility as decimal(10,4)) as rvu_facility,
        cast(rvu_malpractice as decimal(10,4)) as rvu_malpractice,
        cast(rvu_work as decimal(10,4)) + cast(rvu_facility as decimal(10,4)) + cast(rvu_malpractice as decimal(10,4)) as rvu_total
        
    from source
)

select * from renamed
