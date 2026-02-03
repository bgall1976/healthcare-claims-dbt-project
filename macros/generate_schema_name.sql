{% macro generate_schema_name(custom_schema_name, node) -%}
    {#
        Customizes schema naming behavior.
        
        Default dbt behavior: target_schema_custom_schema (e.g., dbt_dev_staging)
        This macro: Just uses the custom schema name when defined
        
        Production: Use schema names directly (staging, marts, features)
        Dev: Prefix with target schema to avoid conflicts
    #}
    
    {%- set default_schema = target.schema -%}
    
    {%- if target.name == 'prod' -%}
        {# In production, use the custom schema name directly #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}
    
    {%- else -%}
        {# In dev/CI, prefix with target schema to avoid collisions #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    
    {%- endif -%}
    
{%- endmacro %}
