# SCD Type 2 Implementation Guide

## What is SCD Type 2?

Slowly Changing Dimension Type 2 (SCD Type 2) is a data warehousing technique for tracking historical changes to dimension data. Instead of overwriting old values, SCD Type 2 creates a new record for each change, preserving the complete history.

## Why SCD Type 2 in Healthcare?

Healthcare analytics often requires understanding data **as it existed at a specific point in time**:

1. **Audit & Compliance**: HIPAA and other regulations may require you to reconstruct data as it existed on any historical date
2. **Longitudinal Studies**: Analyzing patient outcomes relative to when their address, provider, or insurance changed
3. **Claims Attribution**: Correctly attributing claims to the provider/practice that existed at time of service
4. **Network Analysis**: Understanding how provider networks evolved over time

## Implementation in This Project

### dbt Snapshots

We use dbt's built-in snapshot functionality to implement SCD Type 2:

```sql
{% snapshot patient_snapshot %}

{{
    config(
        target_schema='snapshots',
        strategy='check',
        unique_key='patient_id',
        check_cols=['address_line_1', 'city', 'state', 'zip_code', 'plan_type'],
    )
}}

select * from {{ ref('stg_patients') }}

{% endsnapshot %}
```

### Key Configuration Options

| Option | Description |
|--------|-------------|
| `strategy='check'` | Creates new record when any `check_cols` value changes |
| `strategy='timestamp'` | Creates new record when `updated_at` column changes |
| `unique_key` | Natural key that identifies the entity |
| `check_cols` | Columns to monitor for changes |
| `invalidate_hard_deletes` | Handle deleted source records |

### Generated Columns

dbt automatically adds these columns to snapshot tables:

| Column | Description |
|--------|-------------|
| `dbt_scd_id` | Unique identifier for each snapshot record |
| `dbt_updated_at` | When the snapshot was taken |
| `dbt_valid_from` | When this version became effective |
| `dbt_valid_to` | When this version was superseded (NULL if current) |

## Example: Patient Address Change

### Initial Load (January 2023)

| patient_id | city | plan_type | dbt_valid_from | dbt_valid_to |
|------------|------|-----------|----------------|--------------|
| P001 | Boston | HMO | 2023-01-01 | NULL |

### After Patient Moves (March 2024)

| patient_id | city | plan_type | dbt_valid_from | dbt_valid_to |
|------------|------|-----------|----------------|--------------|
| P001 | Boston | HMO | 2023-01-01 | 2024-03-15 |
| P001 | Cambridge | PPO | 2024-03-15 | NULL |

## Querying Historical Data

### Current State Only

```sql
SELECT *
FROM dim_patient
WHERE is_current = TRUE
```

### Point-in-Time Query

Find patient's address as of a specific date:

```sql
SELECT *
FROM dim_patient
WHERE patient_id = 'P001'
  AND '2024-01-15' >= valid_from
  AND ('2024-01-15' < valid_to OR valid_to IS NULL)
```

### Full History

```sql
SELECT 
    patient_id,
    city,
    plan_type,
    valid_from,
    valid_to,
    CASE WHEN is_current THEN 'Current' ELSE 'Historical' END as status
FROM dim_patient
WHERE patient_id = 'P001'
ORDER BY valid_from
```

## Running Snapshots

Snapshots are run separately from regular models:

```bash
# Run all snapshots
dbt snapshot

# Run specific snapshot
dbt snapshot --select patient_snapshot

# Run snapshots then models
dbt snapshot && dbt run
```

## Best Practices

### 1. Choose the Right Strategy

- Use **`check`** when you need to detect changes to specific columns
- Use **`timestamp`** when source has a reliable `updated_at` column

### 2. Be Selective with Check Columns

Only include columns where changes are meaningful:

```sql
-- Good: Track address and plan changes
check_cols=['address', 'city', 'state', 'zip_code', 'plan_type']

-- Bad: Including volatile columns creates excessive history
check_cols=['address', 'last_login_date', 'session_count']
```

### 3. Handle Current vs Historical in Dimensions

Always provide a clear `is_current` flag:

```sql
CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
```

### 4. Join Fact Tables Appropriately

For most analytics, join to current dimension records:

```sql
SELECT f.*, p.*
FROM fact_claims f
JOIN dim_patient p ON f.patient_key = p.patient_key
WHERE p.is_current = TRUE
```

For point-in-time analysis, join based on date ranges:

```sql
SELECT f.*, p.*
FROM fact_claims f
JOIN dim_patient p ON f.patient_id = p.patient_id
  AND f.service_date >= p.valid_from
  AND (f.service_date < p.valid_to OR p.valid_to IS NULL)
```

## Common Pitfalls

1. **Forgetting to run snapshots**: Snapshots must be run regularly (daily in production) to capture changes
2. **Over-tracking**: Including too many columns creates excessive history
3. **Under-tracking**: Missing important columns means losing historical context
4. **Timezone issues**: Ensure consistent timezone handling in `valid_from`/`valid_to`

## References

- [dbt Snapshots Documentation](https://docs.getdbt.com/docs/build/snapshots)
- [Kimball SCD Types](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/)
