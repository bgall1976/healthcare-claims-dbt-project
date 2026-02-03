# Healthcare Claims Data Warehouse

A production-ready dbt project demonstrating modern healthcare data engineering patterns including Kimball dimensional modeling, SCD Type 2 historical tracking, and comprehensive data quality testing.

## 🎯 Project Overview

This project builds a complete healthcare claims analytics data warehouse using:

- **dbt** for transformation and testing
- **Snowflake** (or DuckDB for local development) as the data warehouse
- **CMS Synthetic Claims Data** as the source dataset
- **Kimball dimensional modeling** for analytics-ready structure
- **SCD Type 2 snapshots** for historical tracking
- **GitHub Actions** for CI/CD

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA WAREHOUSE ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│  │   SOURCES    │    │   STAGING    │    │ INTERMEDIATE │                  │
│  │              │───▶│              │───▶│              │                  │
│  │ • Claims     │    │ • stg_claims │    │ • int_claims │                  │
│  │ • Patients   │    │ • stg_patients    │ • int_patients                  │
│  │ • Providers  │    │ • stg_providers   │ • int_providers                 │
│  │ • Diagnoses  │    │ • stg_diagnoses   │                                 │
│  └──────────────┘    └──────────────┘    └──────────────┘                  │
│                                                 │                           │
│                                                 ▼                           │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                              MARTS                                    │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │  │
│  │  │  CORE (Kimball Star Schema)                                     │ │  │
│  │  │  • fact_claims (grain: claim line)                              │ │  │
│  │  │  • dim_patient (SCD Type 2)                                     │ │  │
│  │  │  • dim_provider (SCD Type 2)                                    │ │  │
│  │  │  • dim_procedure                                                │ │  │
│  │  │  • dim_diagnosis                                                │ │  │
│  │  │  • dim_date                                                     │ │  │
│  │  └─────────────────────────────────────────────────────────────────┘ │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │  │
│  │  │  FEATURES (ML-Ready Aggregations)                               │ │  │
│  │  │  • fct_patient_risk_profile                                     │ │  │
│  │  │  • fct_provider_quality_metrics                                 │ │  │
│  │  │  • fct_utilization_summary                                      │ │  │
│  │  └─────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  SNAPSHOTS (SCD Type 2 History)                                      │  │
│  │  • patient_snapshot                                                  │  │
│  │  • provider_snapshot                                                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- Python 3.9+
- One of the following:
  - **Snowflake account** (30-day free trial available)
  - **DuckDB** (free, local development)
- Git
- Basic familiarity with dbt concepts

## 🚀 Quick Start (Windows)

### Option A: Local Development with DuckDB (Recommended for Demo)

DuckDB requires no cloud setup and is perfect for demonstrating the project.

```cmd
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/healthcare-claims-dbt-project.git
cd healthcare-claims-dbt-project

# 2. Create virtual environment
python -m venv venv
venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create .dbt folder and copy profile
mkdir %USERPROFILE%\.dbt
copy profiles\profiles_duckdb.yml %USERPROFILE%\.dbt\profiles.yml

# 5. Verify connection
dbt debug

# 6. Load seed data (synthetic claims)
dbt seed

# 7. Run all models
dbt run

# 8. Run tests
dbt test

# 9. Generate and serve documentation
dbt docs generate
dbt docs serve
```

### Option B: Snowflake Setup (Windows)

```cmd
# 1. Clone and setup virtual environment (same as above)
git clone https://github.com/YOUR_USERNAME/healthcare-claims-dbt-project.git
cd healthcare-claims-dbt-project
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# 2. Set environment variables for Snowflake
set SNOWFLAKE_ACCOUNT=your_account
set SNOWFLAKE_USER=your_username
set SNOWFLAKE_PASSWORD=your_password
set SNOWFLAKE_ROLE=your_role
set SNOWFLAKE_WAREHOUSE=your_warehouse
set SNOWFLAKE_DATABASE=HEALTHCARE_DW

# 3. Create .dbt folder and copy Snowflake profile
mkdir %USERPROFILE%\.dbt
copy profiles\profiles_snowflake.yml %USERPROFILE%\.dbt\profiles.yml

# 4. Create database objects (run in Snowflake)
# See scripts/snowflake_setup.sql

# 5. Verify connection and run
dbt debug
dbt seed
dbt run
dbt test
```

### Alternative: Using PowerShell

If you prefer PowerShell over Command Prompt:

```powershell
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/healthcare-claims-dbt-project.git
cd healthcare-claims-dbt-project

# 2. Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create .dbt folder and copy profile
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.dbt"
Copy-Item profiles\profiles_duckdb.yml "$env:USERPROFILE\.dbt\profiles.yml"

# 5. Run dbt commands
dbt debug
dbt seed
dbt run
dbt test

# 6. Generate and serve documentation
dbt docs generate
dbt docs serve
```

### Troubleshooting Windows Setup

**PowerShell script execution disabled:**
```powershell
# Run PowerShell as Administrator and execute:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**pip not recognized:**
```cmd
# Use python -m pip instead
python -m pip install -r requirements.txt
```

**dbt not found after install:**
```cmd
# Ensure virtual environment is activated
venv\Scripts\activate

# Or run with python -m
python -m dbt debug
```

## 📁 Project Structure

```
healthcare-claims-dbt-project/
│
├── README.md                    # This file
├── dbt_project.yml             # dbt project configuration
├── packages.yml                # dbt package dependencies
├── requirements.txt            # Python dependencies
│
├── profiles/                   # Sample dbt profiles
│   ├── profiles_duckdb.yml
│   └── profiles_snowflake.yml
│
├── seeds/                      # Static reference data & synthetic source data
│   ├── raw_claims.csv
│   ├── raw_patients.csv
│   ├── raw_providers.csv
│   ├── raw_diagnoses.csv
│   ├── ref_icd10_codes.csv
│   ├── ref_cpt_codes.csv
│   └── _seeds.yml
│
├── models/
│   ├── staging/               # 1:1 mapping from source, light cleaning
│   │   ├── _stg_sources.yml
│   │   ├── _stg_models.yml
│   │   ├── stg_claims.sql
│   │   ├── stg_patients.sql
│   │   ├── stg_providers.sql
│   │   └── stg_diagnoses.sql
│   │
│   ├── intermediate/          # Business logic, joins, enrichment
│   │   ├── _int_models.yml
│   │   ├── int_claims_enriched.sql
│   │   ├── int_patient_demographics.sql
│   │   └── int_provider_details.sql
│   │
│   └── marts/
│       ├── core/              # Kimball dimensional model
│       │   ├── _core_models.yml
│       │   ├── dim_patient.sql
│       │   ├── dim_provider.sql
│       │   ├── dim_procedure.sql
│       │   ├── dim_diagnosis.sql
│       │   ├── dim_date.sql
│       │   └── fact_claims.sql
│       │
│       └── features/          # ML feature store tables
│           ├── _features_models.yml
│           ├── fct_patient_risk_profile.sql
│           ├── fct_provider_quality_metrics.sql
│           └── fct_utilization_summary.sql
│
├── snapshots/                 # SCD Type 2 historical tracking
│   ├── patient_snapshot.sql
│   └── provider_snapshot.sql
│
├── macros/                    # Reusable SQL functions
│   ├── generate_schema_name.sql
│   ├── cents_to_dollars.sql
│   └── calculate_age.sql
│
├── tests/                     # Custom data tests
│   ├── assert_claim_amount_positive.sql
│   └── assert_valid_npi.sql
│
├── analyses/                  # Ad-hoc analytical queries
│   ├── cost_by_diagnosis.sql
│   └── provider_utilization.sql
│
├── scripts/                   # Setup and utility scripts
│   ├── snowflake_setup.sql
│   ├── generate_synthetic_data.py
│   └── download_cms_data.sh
│
├── docs/                      # Additional documentation
│   ├── data_dictionary.md
│   ├── scd_type_2_explained.md
│   └── images/
│
└── .github/
    └── workflows/
        └── dbt_ci.yml         # CI/CD pipeline
```

## 📊 Data Model

### Fact Table: `fact_claims`

The central fact table at the **claim line** grain.

| Column | Type | Description |
|--------|------|-------------|
| claim_key | VARCHAR | Surrogate key (claim_id + line_number) |
| claim_id | VARCHAR | Natural key from source |
| line_number | INTEGER | Line item within claim |
| patient_key | VARCHAR | FK to dim_patient |
| provider_key | VARCHAR | FK to dim_provider |
| procedure_key | VARCHAR | FK to dim_procedure |
| diagnosis_key | VARCHAR | FK to dim_diagnosis |
| service_date_key | INTEGER | FK to dim_date |
| paid_date_key | INTEGER | FK to dim_date |
| billed_amount | DECIMAL | Amount billed by provider |
| allowed_amount | DECIMAL | Amount allowed by payer |
| paid_amount | DECIMAL | Amount paid by payer |
| patient_responsibility | DECIMAL | Patient out-of-pocket |
| units | INTEGER | Service units |

### Dimension Tables

#### `dim_patient` (SCD Type 2)
Tracks patient demographic changes over time.

| Column | Type | Description |
|--------|------|-------------|
| patient_key | VARCHAR | Surrogate key |
| patient_id | VARCHAR | Natural key |
| first_name | VARCHAR | |
| last_name | VARCHAR | |
| date_of_birth | DATE | |
| gender | VARCHAR | |
| address_line_1 | VARCHAR | |
| city | VARCHAR | |
| state | VARCHAR | |
| zip_code | VARCHAR | |
| plan_type | VARCHAR | Insurance plan type |
| valid_from | TIMESTAMP | SCD2 start |
| valid_to | TIMESTAMP | SCD2 end |
| is_current | BOOLEAN | Current record flag |

#### `dim_provider` (SCD Type 2)
Tracks provider information changes.

| Column | Type | Description |
|--------|------|-------------|
| provider_key | VARCHAR | Surrogate key |
| npi | VARCHAR | National Provider Identifier |
| provider_name | VARCHAR | |
| specialty | VARCHAR | |
| practice_name | VARCHAR | |
| address | VARCHAR | |
| city | VARCHAR | |
| state | VARCHAR | |
| valid_from | TIMESTAMP | SCD2 start |
| valid_to | TIMESTAMP | SCD2 end |
| is_current | BOOLEAN | Current record flag |

#### `dim_procedure`
CPT/HCPCS procedure codes.

| Column | Type | Description |
|--------|------|-------------|
| procedure_key | VARCHAR | Surrogate key |
| procedure_code | VARCHAR | CPT/HCPCS code |
| procedure_description | VARCHAR | Description |
| procedure_category | VARCHAR | Category grouping |
| rvu_work | DECIMAL | Work RVU |
| rvu_total | DECIMAL | Total RVU |

#### `dim_diagnosis`
ICD-10 diagnosis codes.

| Column | Type | Description |
|--------|------|-------------|
| diagnosis_key | VARCHAR | Surrogate key |
| diagnosis_code | VARCHAR | ICD-10 code |
| diagnosis_description | VARCHAR | Description |
| diagnosis_category | VARCHAR | CCS category |
| is_chronic | BOOLEAN | Chronic condition flag |

#### `dim_date`
Standard date dimension.

| Column | Type | Description |
|--------|------|-------------|
| date_key | INTEGER | YYYYMMDD format |
| full_date | DATE | |
| year | INTEGER | |
| quarter | INTEGER | |
| month | INTEGER | |
| month_name | VARCHAR | |
| week_of_year | INTEGER | |
| day_of_week | INTEGER | |
| day_name | VARCHAR | |
| is_weekend | BOOLEAN | |
| is_holiday | BOOLEAN | |

## 🔄 SCD Type 2 Implementation

This project demonstrates SCD Type 2 (Slowly Changing Dimensions Type 2) using dbt snapshots, which is critical for healthcare analytics where you need to track historical changes.

### Why SCD Type 2 in Healthcare?

- **Audit Compliance**: Track when patient addresses or insurance plans changed
- **Longitudinal Analysis**: Analyze outcomes relative to when changes occurred
- **Point-in-Time Reporting**: Reconstruct data as it existed on any historical date

### How It Works

```sql
-- snapshots/patient_snapshot.sql
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

When patient data changes:

| patient_id | city | plan_type | dbt_valid_from | dbt_valid_to | dbt_scd_id |
|------------|------|-----------|----------------|--------------|------------|
| P001 | Boston | HMO | 2023-01-01 | 2024-03-15 | abc123 |
| P001 | Cambridge | PPO | 2024-03-15 | NULL | def456 |

The `dbt_valid_to = NULL` indicates the current record.

### Querying Historical Data

```sql
-- Find patient's address as of a specific date
SELECT *
FROM {{ ref('patient_snapshot') }}
WHERE patient_id = 'P001'
  AND '2024-01-15' >= dbt_valid_from
  AND '2024-01-15' < COALESCE(dbt_valid_to, '9999-12-31')
```

## ✅ Data Quality Testing

### Built-in dbt Tests

```yaml
# models/marts/core/_core_models.yml
models:
  - name: fact_claims
    columns:
      - name: claim_key
        tests:
          - unique
          - not_null
      - name: patient_key
        tests:
          - not_null
          - relationships:
              to: ref('dim_patient')
              field: patient_key
      - name: paid_amount
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
```

### Custom Tests

```sql
-- tests/assert_claim_amount_positive.sql
-- Ensure no claims have negative paid amounts

SELECT
    claim_key,
    paid_amount
FROM {{ ref('fact_claims') }}
WHERE paid_amount < 0
```

### Test Coverage

Run all tests:
```cmd
dbt test
```

Run specific test types:
```cmd
dbt test --select test_type:generic    # Schema tests
dbt test --select test_type:singular   # Custom SQL tests
```

## 🔧 CI/CD Pipeline

The project includes a GitHub Actions workflow for continuous integration.

```yaml
# .github/workflows/dbt_ci.yml
name: dbt CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  dbt-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          
      - name: Run dbt deps
        run: dbt deps
        
      - name: Run dbt seed
        run: dbt seed --target ci
        
      - name: Run dbt run
        run: dbt run --target ci
        
      - name: Run dbt test
        run: dbt test --target ci
        
      - name: Generate docs
        run: dbt docs generate --target ci
```

## 📈 Sample Analytics Queries

### Total Paid by Diagnosis Category

```sql
SELECT
    d.diagnosis_category,
    COUNT(DISTINCT f.claim_id) AS claim_count,
    SUM(f.paid_amount) AS total_paid,
    AVG(f.paid_amount) AS avg_paid_per_line
FROM {{ ref('fact_claims') }} f
JOIN {{ ref('dim_diagnosis') }} d ON f.diagnosis_key = d.diagnosis_key
GROUP BY d.diagnosis_category
ORDER BY total_paid DESC
```

### Provider Cost Efficiency

```sql
SELECT
    p.provider_name,
    p.specialty,
    COUNT(DISTINCT f.claim_id) AS total_claims,
    SUM(f.billed_amount) AS total_billed,
    SUM(f.paid_amount) AS total_paid,
    ROUND(SUM(f.paid_amount) / NULLIF(SUM(f.billed_amount), 0) * 100, 2) AS payment_rate_pct
FROM {{ ref('fact_claims') }} f
JOIN {{ ref('dim_provider') }} p ON f.provider_key = p.provider_key
WHERE p.is_current = TRUE
GROUP BY p.provider_name, p.specialty
ORDER BY total_paid DESC
```

### Patient History with SCD Type 2

```sql
-- Track a patient's plan changes over time
SELECT
    patient_id,
    plan_type,
    city,
    state,
    valid_from,
    valid_to,
    CASE WHEN is_current THEN 'Current' ELSE 'Historical' END AS record_status
FROM {{ ref('dim_patient') }}
WHERE patient_id = 'P001'
ORDER BY valid_from
```

## 🛡️ HIPAA Considerations

This project uses **synthetic data only** for demonstration purposes. In a production environment:

1. **PHI Handling**: Never commit real PHI to version control
2. **Access Controls**: Implement role-based access in your warehouse
3. **Encryption**: Enable encryption at rest and in transit
4. **Audit Logging**: Enable query logging for compliance
5. **Data Masking**: Apply dynamic masking for sensitive columns

```sql
-- Example: Dynamic masking in Snowflake
CREATE MASKING POLICY ssn_mask AS (val STRING) 
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ANALYST') THEN 'XXX-XX-' || RIGHT(val, 4)
    ELSE val
  END;
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `dbt test`
5. Commit: `git commit -m 'Add my feature'`
6. Push: `git push origin feature/my-feature`
7. Open a Pull Request

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)
- [CMS Synthetic Data](https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/SynPUFs)
- [SCD Type 2 Explained](docs/scd_type_2_explained.md)

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Built for demonstrating healthcare data engineering best practices.**
