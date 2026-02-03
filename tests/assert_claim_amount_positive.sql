/*
    Custom Test: Assert Claim Amounts Are Positive
    
    Healthcare claims should never have negative paid amounts.
    This test returns any rows that violate this business rule.
    
    A passing test returns 0 rows.
*/

select
    claim_key,
    claim_id,
    line_number,
    paid_amount,
    billed_amount,
    'Negative paid amount detected' as failure_reason
from {{ ref('fact_claims') }}
where paid_amount < 0

union all

select
    claim_key,
    claim_id,
    line_number,
    paid_amount,
    billed_amount,
    'Negative billed amount detected' as failure_reason
from {{ ref('fact_claims') }}
where billed_amount < 0
