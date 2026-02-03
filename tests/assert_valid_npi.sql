/*
    Custom Test: Assert Valid NPI Format
    
    National Provider Identifiers (NPIs) must be exactly 10 digits.
    This is a critical healthcare compliance requirement.
    
    A passing test returns 0 rows.
*/

select
    npi,
    provider_full_name,
    'Invalid NPI format' as failure_reason
from {{ ref('dim_provider') }}
where 
    -- NPI must be exactly 10 characters
    length(npi) != 10
    -- NPI must be all numeric
    or npi !~ '^[0-9]+$'
