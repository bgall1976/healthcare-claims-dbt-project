-- =============================================================================
-- Snowflake Setup Script for Healthcare Claims Data Warehouse
-- =============================================================================
-- Run this script in Snowflake with ACCOUNTADMIN role before running dbt
-- =============================================================================

-- 1. Create the database
CREATE DATABASE IF NOT EXISTS HEALTHCARE_DW;

-- 2. Create schemas
USE DATABASE HEALTHCARE_DW;

CREATE SCHEMA IF NOT EXISTS RAW;        -- For seed data
CREATE SCHEMA IF NOT EXISTS STAGING;    -- For staging models
CREATE SCHEMA IF NOT EXISTS MARTS;      -- For dimensional models
CREATE SCHEMA IF NOT EXISTS FEATURES;   -- For ML feature tables
CREATE SCHEMA IF NOT EXISTS SNAPSHOTS;  -- For SCD Type 2 snapshots

-- 3. Create a warehouse for transformations
CREATE WAREHOUSE IF NOT EXISTS TRANSFORM_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 4. Create roles for least-privilege access
CREATE ROLE IF NOT EXISTS TRANSFORM_ROLE;
CREATE ROLE IF NOT EXISTS ANALYST_ROLE;

-- 5. Grant permissions to transform role (used by dbt)
GRANT USAGE ON DATABASE HEALTHCARE_DW TO ROLE TRANSFORM_ROLE;
GRANT ALL ON ALL SCHEMAS IN DATABASE HEALTHCARE_DW TO ROLE TRANSFORM_ROLE;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE HEALTHCARE_DW TO ROLE TRANSFORM_ROLE;
GRANT ALL ON ALL TABLES IN DATABASE HEALTHCARE_DW TO ROLE TRANSFORM_ROLE;
GRANT ALL ON FUTURE TABLES IN DATABASE HEALTHCARE_DW TO ROLE TRANSFORM_ROLE;
GRANT ALL ON ALL VIEWS IN DATABASE HEALTHCARE_DW TO ROLE TRANSFORM_ROLE;
GRANT ALL ON FUTURE VIEWS IN DATABASE HEALTHCARE_DW TO ROLE TRANSFORM_ROLE;
GRANT USAGE ON WAREHOUSE TRANSFORM_WH TO ROLE TRANSFORM_ROLE;

-- 6. Grant permissions to analyst role (read-only)
GRANT USAGE ON DATABASE HEALTHCARE_DW TO ROLE ANALYST_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE HEALTHCARE_DW TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN DATABASE HEALTHCARE_DW TO ROLE ANALYST_ROLE;
GRANT SELECT ON FUTURE TABLES IN DATABASE HEALTHCARE_DW TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL VIEWS IN DATABASE HEALTHCARE_DW TO ROLE ANALYST_ROLE;
GRANT SELECT ON FUTURE VIEWS IN DATABASE HEALTHCARE_DW TO ROLE ANALYST_ROLE;
GRANT USAGE ON WAREHOUSE TRANSFORM_WH TO ROLE ANALYST_ROLE;

-- 7. Create a service account user for dbt (optional - for CI/CD)
-- CREATE USER IF NOT EXISTS DBT_SERVICE_ACCOUNT
--     PASSWORD = 'CHANGE_ME_IMMEDIATELY'
--     DEFAULT_ROLE = TRANSFORM_ROLE
--     DEFAULT_WAREHOUSE = TRANSFORM_WH
--     DEFAULT_NAMESPACE = HEALTHCARE_DW.RAW;

-- GRANT ROLE TRANSFORM_ROLE TO USER DBT_SERVICE_ACCOUNT;

-- =============================================================================
-- CI Environment (separate database for testing)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS HEALTHCARE_DW_CI;

GRANT ALL ON DATABASE HEALTHCARE_DW_CI TO ROLE TRANSFORM_ROLE;

USE DATABASE HEALTHCARE_DW_CI;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS MARTS;
CREATE SCHEMA IF NOT EXISTS FEATURES;
CREATE SCHEMA IF NOT EXISTS SNAPSHOTS;

GRANT ALL ON ALL SCHEMAS IN DATABASE HEALTHCARE_DW_CI TO ROLE TRANSFORM_ROLE;

-- =============================================================================
-- Verification Queries
-- =============================================================================

-- Check database setup
SHOW DATABASES LIKE 'HEALTHCARE%';
SHOW SCHEMAS IN DATABASE HEALTHCARE_DW;
SHOW WAREHOUSES LIKE 'TRANSFORM%';
SHOW ROLES LIKE '%ROLE';

-- =============================================================================
-- HIPAA Considerations (implement as needed)
-- =============================================================================

-- Example: Enable query logging for audit
-- ALTER ACCOUNT SET ENABLE_QUERY_ACCELERATION = TRUE;

-- Example: Create masking policy for SSN (if applicable)
-- CREATE OR REPLACE MASKING POLICY SSN_MASK AS (val STRING) 
-- RETURNS STRING ->
--   CASE
--     WHEN CURRENT_ROLE() IN ('ANALYST_ROLE') THEN 'XXX-XX-' || RIGHT(val, 4)
--     ELSE val
--   END;

-- Example: Apply row access policy (for multi-tenant scenarios)
-- CREATE OR REPLACE ROW ACCESS POLICY PATIENT_ACCESS AS (patient_id VARCHAR)
-- RETURNS BOOLEAN ->
--   CURRENT_ROLE() IN ('TRANSFORM_ROLE', 'ADMIN_ROLE')
--   OR patient_id IN (SELECT patient_id FROM authorized_patients WHERE user_id = CURRENT_USER());
