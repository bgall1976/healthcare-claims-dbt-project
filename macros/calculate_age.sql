{% macro calculate_age(date_of_birth, as_of_date=none) %}
    {#
        Calculates age in years from date of birth.
        
        Args:
            date_of_birth: The birth date column
            as_of_date: Optional reference date (defaults to current_date)
        
        Usage: 
            {{ calculate_age('date_of_birth') }}
            {{ calculate_age('date_of_birth', 'service_date') }}
    #}
    
    {%- set reference_date = as_of_date if as_of_date else 'current_date' -%}
    
    {{ dbt.datediff(date_of_birth, reference_date, 'year') }}
    
{% endmacro %}


{% macro age_group(age_column) %}
    {#
        Categorizes age into standard healthcare analytics groups.
        
        Usage: {{ age_group('patient_age') }} as age_group
    #}
    
    case 
        when {{ age_column }} < 0 then 'Invalid'
        when {{ age_column }} < 1 then 'Infant (<1)'
        when {{ age_column }} < 5 then 'Early Childhood (1-4)'
        when {{ age_column }} < 12 then 'Child (5-11)'
        when {{ age_column }} < 18 then 'Adolescent (12-17)'
        when {{ age_column }} < 26 then 'Young Adult (18-25)'
        when {{ age_column }} < 35 then 'Adult (26-34)'
        when {{ age_column }} < 45 then 'Adult (35-44)'
        when {{ age_column }} < 55 then 'Adult (45-54)'
        when {{ age_column }} < 65 then 'Adult (55-64)'
        when {{ age_column }} < 75 then 'Senior (65-74)'
        when {{ age_column }} < 85 then 'Senior (75-84)'
        else 'Elderly (85+)'
    end
    
{% endmacro %}
