{{
    config(
        materialized='table',
        tags=['core', 'dimension']
    )
}}

{# Generate a date spine from 2020 to 2030 #}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    ) }}
),

dates as (
    select
        cast(date_day as date) as full_date
    from date_spine
),

final as (
    select
        -- Surrogate key
        cast({{ dbt.date_trunc('day', 'full_date') }} as varchar) as date_key,
        
        -- Date value
        full_date,
        
        -- Calendar attributes
        extract(year from full_date) as year,
        extract(quarter from full_date) as quarter,
        extract(month from full_date) as month,
        extract(day from full_date) as day_of_month,
        extract(dow from full_date) as day_of_week,
        extract(week from full_date) as week_of_year,
        
        -- Text attributes
        case extract(month from full_date)
            when 1 then 'January'
            when 2 then 'February'
            when 3 then 'March'
            when 4 then 'April'
            when 5 then 'May'
            when 6 then 'June'
            when 7 then 'July'
            when 8 then 'August'
            when 9 then 'September'
            when 10 then 'October'
            when 11 then 'November'
            when 12 then 'December'
        end as month_name,
        
        case extract(dow from full_date)
            when 0 then 'Sunday'
            when 1 then 'Monday'
            when 2 then 'Tuesday'
            when 3 then 'Wednesday'
            when 4 then 'Thursday'
            when 5 then 'Friday'
            when 6 then 'Saturday'
        end as day_name,
        
        -- Fiscal calendar (assuming calendar year = fiscal year)
        extract(year from full_date) as fiscal_year,
        extract(quarter from full_date) as fiscal_quarter,
        
        -- Flags
        case 
            when extract(dow from full_date) in (0, 6) then true 
            else false 
        end as is_weekend,
        
        -- Relative date flags (calculated at query time in practice)
        case when full_date = current_date then true else false end as is_today,
        
        -- Period keys for easy grouping
        cast(extract(year from full_date) as varchar) || '-' || 
            lpad(cast(extract(month from full_date) as varchar), 2, '0') as year_month,
        cast(extract(year from full_date) as varchar) || '-Q' || 
            cast(extract(quarter from full_date) as varchar) as year_quarter
        
    from dates
)

select * from final
