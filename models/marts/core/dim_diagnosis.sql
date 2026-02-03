{{
    config(
        materialized='table',
        tags=['core', 'dimension']
    )
}}

with diagnoses as (
    select * from {{ ref('stg_diagnoses') }}
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['diagnosis_code']) }} as diagnosis_key,
        
        -- Natural key
        diagnosis_code,
        
        -- Attributes
        diagnosis_description,
        diagnosis_category,
        icd_chapter,
        is_chronic_condition,
        
        -- ICD-10 hierarchy extraction
        -- ICD-10 codes have structure: Category (3 chars) + subcategory
        left(diagnosis_code, 3) as icd_category_code,
        left(diagnosis_code, 1) as icd_chapter_letter,
        
        -- Common chronic condition groupings for analytics
        case 
            when diagnosis_code like 'E11%' then 'Diabetes'
            when diagnosis_code like 'I10%' or diagnosis_code like 'I11%' then 'Hypertension'
            when diagnosis_code like 'J45%' then 'Asthma'
            when diagnosis_code like 'F32%' or diagnosis_code like 'F33%' then 'Depression'
            when diagnosis_code like 'J44%' then 'COPD'
            when diagnosis_code like 'I25%' then 'Coronary Artery Disease'
            else null
        end as chronic_condition_group
        
    from diagnoses
)

select * from final
