{{
    config(
        materialized='table',
        tags=['core', 'dimension']
    )
}}

with procedures as (
    select * from {{ ref('stg_procedures') }}
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['procedure_code']) }} as procedure_key,
        
        -- Natural key
        procedure_code,
        
        -- Attributes
        procedure_description,
        procedure_category,
        is_surgical,
        
        -- RVU components (useful for cost analysis)
        rvu_work,
        rvu_facility,
        rvu_malpractice,
        rvu_total,
        
        -- Derived: complexity tier based on RVU
        case
            when rvu_total = 0 then 'Lab/Ancillary'
            when rvu_total < 1 then 'Low Complexity'
            when rvu_total < 3 then 'Medium Complexity'
            when rvu_total < 5 then 'High Complexity'
            else 'Very High Complexity'
        end as complexity_tier
        
    from procedures
)

select * from final
