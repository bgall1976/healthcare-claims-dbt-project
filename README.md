# Healthcare Claims Data Warehouse

A production-ready dbt project demonstrating modern healthcare data engineering patterns including Kimball dimensional modeling, SCD Type 2 historical tracking, and comprehensive data quality testing.

## 🎯 Project Overview

This project builds a complete healthcare claims analytics data warehouse using:

- **dbt** for transformation and testing
- **Snowflake** as the data warehouse
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
- **Snowflake account** (30-day free trial available at https://signup.snowflake.com/)
- Git
- Basic familiarity with dbt concepts

---

## 🚀 Quick Start (Windows)

---

### Step 1: Clone the Repository

```cmd
git clone https://github.com/bgall1976/healthcare-claims-dbt-project.git
cd healthcare-claims-dbt-project
```

**What this does:**
- `git clone` downloads a complete copy of the project from GitHub to your local machine
- `cd` changes your current directory into the newly created project folder

**Why it's needed:**
- You need the project files locally to run dbt commands
- Cloning preserves the Git history, allowing you to track changes and push updates

---

### Step 2: Create Virtual Environment

```cmd
python -m venv venv
venv\Scripts\activate
```

**What this does:**
- `python -m venv venv` creates an isolated Python environment in a folder called `venv`
- `venv\Scripts\activate` activates the virtual environment (you'll see `(venv)` in your command prompt)

**Why it's needed:**
- **Isolation**: Keeps this project's Python packages separate from other projects
- **Reproducibility**: Ensures everyone uses the same package versions
- **Clean uninstall**: Delete the `venv` folder to remove all packages
- **Best practice**: Standard in Python development to avoid dependency conflicts

**How to verify:** Your command prompt should show `(venv)` at the beginning:
```
(venv) C:\Users\Dell\Documents\healthcare-claims-dbt-project>
```

---

### Step 3: Install Dependencies

```cmd
python -m pip install --upgrade pip
python -m pip install dbt-snowflake
```

**What this does:**
- Upgrades pip to the latest version
- Installs dbt with the Snowflake adapter

**Why it's needed:**
- dbt is a Python package that must be installed before you can use it
- The Snowflake adapter allows dbt to connect to your Snowflake data warehouse

**Important:** Use `python -m pip install` to ensure packages install in the virtual environment, not globally.

---

### Step 4: Set Environment Variables for Snowflake

**⚠️ IMPORTANT: Run each command on a separate line!**

```cmd
set SNOWFLAKE_ACCOUNT=ZSPGHZC-HXC41003
set SNOWFLAKE_USER=SNOWFLAKE
set "SNOWFLAKE_PASSWORD=your_password_here"
set SNOWFLAKE_ROLE=ACCOUNTADMIN
set SNOWFLAKE_WAREHOUSE=COMPUTE_WH
set SNOWFLAKE_DATABASE=HEALTHCARE_DW
```

**Replace `your_password_here` with your actual Snowflake password.**

**⚠️ Note:** If your password contains special characters (`%`, `&`, `@`, `)`, `(`, etc.), you MUST wrap the entire command in quotes as shown above: `set "SNOWFLAKE_PASSWORD=your_password"`

**What this does:**
- Creates temporary environment variables in your current command prompt session
- These variables store your Snowflake connection credentials
- The dbt profile reads these variables to connect to Snowflake

**Why it's needed:**
- **Security**: Keeps passwords out of config files that might be committed to Git
- **Flexibility**: Easy to change credentials without editing files
- **Best practice**: Standard approach for managing secrets in development

**Where to find these values:**

| Variable | Value | How to Find It |
|----------|-------|----------------|
| SNOWFLAKE_ACCOUNT | `ZSPGHZC-HXC41003` | Snowflake → Account → Account identifier |
| SNOWFLAKE_USER | `SNOWFLAKE` | Your Snowflake login username |
| SNOWFLAKE_PASSWORD | Your password | The password you use to log into Snowflake |
| SNOWFLAKE_ROLE | `ACCOUNTADMIN` | Default admin role |
| SNOWFLAKE_WAREHOUSE | `COMPUTE_WH` | Compute warehouse name |
| SNOWFLAKE_DATABASE | `HEALTHCARE_DW` | Database for this project |

**To verify the variables are set:**
```cmd
echo %SNOWFLAKE_ACCOUNT%
```
This should print: `ZSPGHZC-HXC41003`

**Note:** These variables only last for the current command prompt session. If you close the window, you'll need to set them again.

---

### Step 5: Create .dbt Folder and Copy Snowflake Profile

```cmd
mkdir %USERPROFILE%\.dbt
copy profiles\profiles_snowflake.yml %USERPROFILE%\.dbt\profiles.yml
```

**What this does:**
- `mkdir %USERPROFILE%\.dbt` creates a hidden `.dbt` folder in your user directory (e.g., `C:\Users\Dell\.dbt`)
- `copy` copies the pre-configured Snowflake profile to that folder, renaming it to `profiles.yml`

**Why it's needed:**
- dbt requires a `profiles.yml` file to know **how to connect** to your data warehouse
- dbt always looks for this file in `~/.dbt/profiles.yml` (your user's home directory)
- The profile contains connection details that reference the environment variables you set

**What's in the Snowflake profile:**
```yaml
healthcare_claims:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      schema: RAW
```

The `{{ env_var('...') }}` syntax tells dbt to read values from environment variables.

---

### Step 6: Create Database Objects in Snowflake

Before running dbt, you need to create the database and schemas in Snowflake.

**Run this SQL in your Snowflake worksheet:**

```sql
-- Create database
CREATE DATABASE IF NOT EXISTS HEALTHCARE_DW;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DW.RAW;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DW.STAGING;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DW.MARTS;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DW.SNAPSHOTS;

-- Create warehouse (if needed)
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
```

**Why it's needed:**
- dbt needs a database and schemas to exist before it can create tables
- The warehouse provides compute resources to run queries
- Schemas organize tables by layer (raw, staging, marts)

---

### Step 7: Verify Connection

```cmd
dbt debug
```

**What this does:**
- Tests that dbt is properly installed
- Validates your `profiles.yml` configuration
- Attempts to connect to Snowflake
- Checks that the `dbt_project.yml` file is valid

**Why it's needed:**
- **Catches configuration errors early** before you try to run models
- Confirms dbt can find and read your profile
- Verifies Snowflake connectivity

**Expected output (success):**
```
Configuration:
  profiles.yml file [OK found and valid]
  dbt_project.yml file [OK found and valid]

Required dependencies:
  - git [OK found]

Connection:
  account: ZSPGHZC-HXC41003
  user: SNOWFLAKE
  database: HEALTHCARE_DW
  warehouse: COMPUTE_WH
  ...
  Connection test: [OK connection ok]

All checks passed!
```

**If it fails:** Check that:
- Virtual environment is activated (`(venv)` in prompt)
- Environment variables are set (run `echo %SNOWFLAKE_ACCOUNT%`)
- `profiles.yml` exists in `C:\Users\YourName\.dbt\`
- Your Snowflake credentials are correct

---

### Step 8: Load Seed Data

```cmd
dbt seed
```

**What this does:**
- Reads all CSV files from the `seeds/` folder
- Creates tables in Snowflake and loads the CSV data into them
- These become your source data for the project

**Why it's needed:**
- This project uses **synthetic healthcare data** stored in CSV files
- dbt seeds turn these CSVs into database tables that models can reference
- In production, you'd have real data sources; seeds simulate this for demos

**What gets loaded:**

| Seed File | Table Created | Purpose |
|-----------|---------------|---------|
| raw_claims.csv | raw_claims | Healthcare claim transactions |
| raw_patients.csv | raw_patients | Patient demographics |
| raw_providers.csv | raw_providers | Healthcare provider info |
| ref_icd10_codes.csv | ref_icd10_codes | Diagnosis code reference |
| ref_cpt_codes.csv | ref_cpt_codes | Procedure code reference |

**Expected output:**
```
Running with dbt=1.7.0
Found 6 seeds

Completed successfully

Done. PASS=6 WARN=0 ERROR=0 SKIP=0 TOTAL=6
```

---

### Step 9: Run All Models

```cmd
dbt run
```

**What this does:**
- Executes all SQL models in the `models/` folder in dependency order
- Creates views and tables in Snowflake based on the SQL transformations
- Builds the entire data pipeline: staging → intermediate → marts

**Why it's needed:**
- This is the **core of dbt** - transforming raw data into analytics-ready tables
- Models are SQL SELECT statements that dbt materializes as views or tables
- Running models builds your dimensional data warehouse (facts + dimensions)

**What gets built:**
```
Staging Layer (views):
  └── stg_claims, stg_patients, stg_providers, stg_diagnoses

Intermediate Layer (ephemeral):
  └── int_claims_enriched, int_patient_demographics, int_provider_details

Marts Layer (tables):
  └── Core: fact_claims, dim_patient, dim_provider, dim_procedure, dim_diagnosis, dim_date
  └── Features: fct_patient_risk_profile, fct_provider_quality_metrics
```

**Expected output:**
```
Running with dbt=1.7.0
Found 15 models

Completed successfully

Done. PASS=15 WARN=0 ERROR=0 SKIP=0 TOTAL=15
```

---

### Step 10: Run Tests

```cmd
dbt test
```

**What this does:**
- Runs all data quality tests defined in the project
- Checks constraints like: unique keys, not null, valid relationships, value ranges
- Reports any data quality issues found

**Why it's needed:**
- **Data quality assurance**: Ensures your transformations produced valid data
- **Catches bugs**: Finds issues like duplicate keys, null values, broken references
- **Documentation**: Tests serve as executable documentation of data expectations
- **CI/CD**: Tests run automatically in pipelines to prevent bad data from deploying

**Types of tests run:**

| Test Type | What It Checks | Example |
|-----------|----------------|---------|
| unique | No duplicate values | `claim_key` is unique |
| not_null | No NULL values | `patient_id` is never null |
| relationships | Foreign key integrity | Every `patient_key` exists in `dim_patient` |
| accepted_values | Valid value list | `gender` is 'M', 'F', or 'U' |
| accepted_range | Numeric bounds | `paid_amount` >= 0 |

**Expected output:**
```
Running with dbt=1.7.0
Found 25 tests

Completed successfully

Done. PASS=25 WARN=0 ERROR=0 SKIP=0 TOTAL=25
```

---

### Step 11: Generate and Serve Documentation

```cmd
dbt docs generate
dbt docs serve
```

**What this does:**
- `dbt docs generate` scans all models, tests, and descriptions to create documentation
- `dbt docs serve` starts a local web server and opens your browser to view the docs

**Why it's needed:**
- **Auto-generated documentation**: Creates a complete data catalog from your code
- **Lineage graphs**: Visual DAG showing how data flows through models
- **Column descriptions**: Shows all columns, types, and tests for each model
- **Searchable**: Find any model, column, or test quickly
- **Stakeholder-friendly**: Non-technical users can explore the data warehouse

**What you'll see:**
- A web browser opens to `http://localhost:8080`
- Interactive lineage graph showing model dependencies
- Click any model to see its SQL, columns, and tests
- Search bar to find any object

**To stop the server:** Press `Ctrl+C` in the command prompt

---

## 🔄 Quick Reference: Coming Back Later

If you close the command prompt and come back later, run these commands:

```cmd
cd C:\Users\Dell\Documents\github_portfolio\healthcare-claims-dbt-project
venv\Scripts\activate
set SNOWFLAKE_ACCOUNT=ZSPGHZC-HXC41003
set SNOWFLAKE_USER=SNOWFLAKE
set "SNOWFLAKE_PASSWORD=your_password_here"
set SNOWFLAKE_ROLE=ACCOUNTADMIN
set SNOWFLAKE_WAREHOUSE=COMPUTE_WH
set SNOWFLAKE_DATABASE=HEALTHCARE_DW
```

Then you can run any dbt command (`dbt run`, `dbt test`, etc.)

---

## 🔧 Alternative: Using PowerShell

If you prefer PowerShell over Command Prompt:

```powershell
# 1. Clone the repository
git clone https://github.com/bgall1976/healthcare-claims-dbt-project.git
cd healthcare-claims-dbt-project

# 2. Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# 3. Install dependencies
python -m pip install --upgrade pip
python -m pip install dbt-snowflake

# 4. Set environment variables (PowerShell syntax)
$env:SNOWFLAKE_ACCOUNT = "ZSPGHZC-HXC41003"
$env:SNOWFLAKE_USER = "SNOWFLAKE"
$env:SNOWFLAKE_PASSWORD = "your_password_here"
$env:SNOWFLAKE_ROLE = "ACCOUNTADMIN"
$env:SNOWFLAKE_WAREHOUSE = "COMPUTE_WH"
$env:SNOWFLAKE_DATABASE = "HEALTHCARE_DW"

# 5. Create .dbt folder and copy profile
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.dbt"
Copy-Item profiles\profiles_snowflake.yml "$env:USERPROFILE\.dbt\profiles.yml"

# 6. Run dbt commands
dbt debug
dbt seed
dbt run
dbt test

# 7. Generate and serve documentation
dbt docs generate
dbt docs serve
```

**PowerShell differences:**
- Uses `.\venv\Scripts\Activate.ps1` instead of `venv\Scripts\activate`
- Uses `$env:VARIABLE = "value"` instead of `set VARIABLE=value`
- Uses `New-Item` and `Copy-Item` cmdlets instead of `mkdir` and `copy`

---

## 🔧 Troubleshooting Windows Setup

**'dbt' is not recognized after install:**
```cmd
# Make sure virtual environment is activated (you should see (venv) in prompt)
venv\Scripts\activate

# If packages installed globally instead of in venv, reinstall:
python -m pip install dbt-snowflake

# Or run dbt via Python module
python -m dbt debug
```

**Packages installing to wrong location:**
```cmd
# Always use python -m pip to ensure correct location
python -m pip install dbt-snowflake

# Verify where dbt is installed (should be in venv folder)
where dbt
```

**PowerShell script execution disabled:**
```powershell
# Run PowerShell as Administrator and execute:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**pip not recognized:**
```cmd
# Use python -m pip instead
python -m pip install dbt-snowflake
```

**Environment variables not working:**
```cmd
# Verify they are set
echo %SNOWFLAKE_ACCOUNT%

# If empty, re-run the set commands (each on its own line!)
set SNOWFLAKE_ACCOUNT=ZSPGHZC-HXC41003

# For passwords with special characters, use quotes:
set "SNOWFLAKE_PASSWORD=your_password_here"
```

**dbt debug fails with connection error:**
```cmd
# Check that all environment variables are set
echo %SNOWFLAKE_ACCOUNT%
echo %SNOWFLAKE_USER%
echo %SNOWFLAKE_DATABASE%

# Verify profiles.yml exists
dir %USERPROFILE%\.dbt\profiles.yml
```

---

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
│   └── generate_synthetic_data.py
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
          pip install dbt-snowflake
          
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
- [Snowflake Documentation](https://docs.snowflake.com/)
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)
- [CMS Synthetic Data](https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/SynPUFs)
- [SCD Type 2 Explained](docs/scd_type_2_explained.md)

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Built for demonstrating healthcare data engineering best practices with Snowflake.**
