{% macro cents_to_dollars(column_name) %}
    {# 
        Converts an amount stored in cents (integer) to dollars (decimal).
        Storing monetary values as integers avoids floating point precision issues.
        
        Usage: {{ cents_to_dollars('amount_cents') }}
        Returns: amount_cents / 100.0 as decimal
    #}
    round(cast({{ column_name }} as decimal(18,2)) / 100.0, 2)
{% endmacro %}
