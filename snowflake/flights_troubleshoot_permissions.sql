-- Snowflake Permissions Troubleshooting Guide
-- =============================================

-- Step 1: Check your current context and permissions
-- --------------------------------------------------
SELECT CURRENT_USER() as current_user;
SELECT CURRENT_ROLE() as current_role;
SELECT CURRENT_DATABASE() as current_database;
SELECT CURRENT_SCHEMA() as current_schema;
SELECT CURRENT_WAREHOUSE() as current_warehouse;

-- Step 2: List all available roles for your user
-- -----------------------------------------------
SHOW GRANTS TO USER SYSTEM$USER;

-- Alternative way to see your roles
SELECT * FROM TABLE(INFORMATION_SCHEMA.APPLICABLE_ROLES());

-- Step 3: Check what databases you have access to
-- ------------------------------------------------
SHOW DATABASES;

-- Step 4: Try switching to a role with more permissions
-- ----------------------------------------------------
-- Common roles to try (uncomment and try one at a time):

-- USE ROLE ACCOUNTADMIN;  -- Most privileged role
-- USE ROLE SYSADMIN;      -- System administrator
-- USE ROLE SECURITYADMIN; -- Security administrator  
-- USE ROLE PUBLIC;        -- Default role

-- Step 5: Check if you need to set a warehouse context
-- -----------------------------------------------------
-- List available warehouses
SHOW WAREHOUSES;

-- Set a warehouse (replace WAREHOUSE_NAME with actual name)
-- USE WAREHOUSE COMPUTE_WH;  -- Common default warehouse name
-- USE WAREHOUSE WAREHOUSE_NAME;

-- Step 6: Alternative approach - Use SNOWFLAKE database
-- -----------------------------------------------------
-- If RECRUITMENT_DB access is restricted, try working with SNOWFLAKE database
USE DATABASE SNOWFLAKE;
USE SCHEMA INFORMATION_SCHEMA;

-- Check what you can access in SNOWFLAKE database
SHOW SCHEMAS IN DATABASE SNOWFLAKE;

-- Step 7: Create your own database (if permitted)
-- -----------------------------------------------
-- Try creating your own database for the exercise
-- CREATE DATABASE IF NOT EXISTS MY_FLIGHTS_DB;
-- USE DATABASE MY_FLIGHTS_DB;
-- CREATE SCHEMA IF NOT EXISTS candidate_1234;
-- USE SCHEMA candidate_1234;

-- Step 8: Request access from administrator
-- -----------------------------------------
-- If none of the above work, you may need to request access
-- Contact your Snowflake administrator and ask for:
-- 1. USAGE privilege on RECRUITMENT_DB database
-- 2. USAGE privilege on PUBLIC schema
-- 3. SELECT privilege on the S3_FOLDER stage
-- 4. CREATE privilege on the schema you want to work in

-- SOLUTION ATTEMPTS (try these in order):
-- =======================================

-- Option 1: Switch to SYSADMIN role (most common solution)
USE ROLE SYSADMIN;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA PUBLIC;

-- Option 2: Use a warehouse
USE WAREHOUSE COMPUTE_WH;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA PUBLIC;

-- Option 3: Check if the stage exists and is accessible
-- LIST @RECRUITMENT_DB.PUBLIC.S3_FOLDER;

-- Option 4: Work with your own schema
-- CREATE DATABASE IF NOT EXISTS MY_WORK_DB;
-- USE DATABASE MY_WORK_DB;
-- CREATE SCHEMA IF NOT EXISTS flights_analysis;
-- USE SCHEMA flights_analysis;


SHOW FILE FORMATS;