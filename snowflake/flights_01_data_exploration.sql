-- Flights Case Study - Phase 1: Data Exploration
-- ================================================

-- Step 1: Connect to Snowflake and Explore Data
-- ----------------------------------------------
USE DATABASE RECRUITMENT_DB;
USE SCHEMA PUBLIC;

-- List files in the stage to confirm data availability
LIST @RECRUITMENT_DB.PUBLIC.S3_FOLDER;

-- Explore the file structure without loading (first 10 fields)
SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
LIMIT 10;

-- Get a broader view of the file structure
SELECT *
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
LIMIT 5;

-- Step 2: Create Working Schema
-- -----------------------------
-- Replace #### with your actual candidate number
CREATE SCHEMA IF NOT EXISTS "candidate_1234";
USE SCHEMA "candidate_1234";

-- Step 3: Initial File Format Testing
-- ------------------------------------
-- Test different file format options to understand the data structure
CREATE OR REPLACE FILE FORMAT pipe_delimited_format
TYPE = 'CSV'
FIELD_DELIMITER = '|'
RECORD_DELIMITER = '\n'
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
ENCODING = 'UTF8'
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- Test the format
SELECT $1, $2, $3, $4, $5
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
(FILE_FORMAT => pipe_delimited_format)
LIMIT 10;

-- Step 4: Determine Column Structure
-- ----------------------------------
-- Get header row to understand column names
SELECT $1 as header_row
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
(FILE_FORMAT => 'CSV', SKIP_HEADER => 0)
LIMIT 1;

-- Count total columns in the file
SELECT 
    COUNT(*) as num_columns_in_row
FROM (
    SELECT SPLIT($1, '|') as columns
    FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
    (FILE_FORMAT => 'CSV', SKIP_HEADER => 0)
    LIMIT 1
) 
CROSS JOIN TABLE(FLATTEN(columns));

-- Step 5: Create Staging Table with All VARCHAR
-- ----------------------------------------------
-- Based on common flight data fields, create staging table
CREATE OR REPLACE TABLE STAGING_FLIGHTS_RAW (
    "TRANSACTIONID" VARCHAR(255),
    "AIRLINE" VARCHAR(10),
    "AIRLINENAME" VARCHAR(255),
    "ORIGAIRPORT" VARCHAR(10),
    "ORIGAIRPORTNAME" VARCHAR(255),
    "DESTAIRPORT" VARCHAR(10), 
    "DESTAIRPORTNAME" VARCHAR(255),
    "DISTANCE" VARCHAR(20),
    "CANCELLED" VARCHAR(10),
    "DEPTIME" VARCHAR(20),
    "ARRTIME" VARCHAR(20),
    "DEPDELAY" VARCHAR(20),
    "ARRDELAY" VARCHAR(20),
    "FLIGHTDATE" VARCHAR(20),
    "TAILNUM" VARCHAR(20)
    -- Add additional columns as discovered
);

-- Step 6: Load Sample Data
-- ------------------------
-- Load a small sample first to validate structure
COPY INTO STAGING_FLIGHTS_RAW
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
FILE_FORMAT = pipe_delimited_format
VALIDATION_MODE = 'RETURN_ERRORS'
LIMIT 100;

-- If successful, load all data
COPY INTO STAGING_FLIGHTS_RAW
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
FILE_FORMAT = pipe_delimited_format;

-- Step 7: Initial Data Validation
-- --------------------------------
-- Check if load was successful
SELECT COUNT(*) as total_rows FROM STAGING_FLIGHTS_RAW;

-- Look at sample data
SELECT * FROM STAGING_FLIGHTS_RAW LIMIT 10;

-- Check for completely empty rows
SELECT COUNT(*) as empty_transaction_ids
FROM STAGING_FLIGHTS_RAW 
WHERE "TRANSACTIONID" IS NULL OR TRIM("TRANSACTIONID") = '';

-- Step 8: Initial Data Type Analysis
-- -----------------------------------
-- Check numeric fields
SELECT 
    COUNT(*) as total_rows,
    COUNT(TRY_CAST("DISTANCE" AS NUMBER)) as valid_distances,
    COUNT(TRY_CAST("DEPDELAY" AS NUMBER)) as valid_dep_delays,
    COUNT(TRY_CAST("ARRDELAY" AS NUMBER)) as valid_arr_delays
FROM STAGING_FLIGHTS_RAW;

-- Check time fields  
SELECT 
    COUNT(TRY_CAST("DEPTIME" AS TIME)) as valid_dep_times,
    COUNT(TRY_CAST("ARRTIME" AS TIME)) as valid_arr_times,
    COUNT(TRY_CAST("FLIGHTDATE" AS DATE)) as valid_flight_dates
FROM STAGING_FLIGHTS_RAW;

-- Step 9: Identify Data Quality Issues
-- -------------------------------------
-- Find rows with invalid numeric data
SELECT 
    "TRANSACTIONID",
    "DISTANCE",
    "DEPDELAY", 
    "ARRDELAY"
FROM STAGING_FLIGHTS_RAW
WHERE TRY_CAST("DISTANCE" AS NUMBER) IS NULL 
   AND TRIM("DISTANCE") != ''
LIMIT 20;

-- Find rows with invalid time data
SELECT 
    "TRANSACTIONID",
    "DEPTIME",
    "ARRTIME"
FROM STAGING_FLIGHTS_RAW  
WHERE (TRY_CAST("DEPTIME" AS TIME) IS NULL AND TRIM("DEPTIME") != '')
   OR (TRY_CAST("ARRTIME" AS TIME) IS NULL AND TRIM("ARRTIME") != '')
LIMIT 20;

-- Step 10: Basic Statistics
-- -------------------------
-- Get basic statistics for numeric fields
SELECT 
    'DISTANCE' as field_name,
    COUNT(*) as total_count,
    COUNT(TRY_CAST("DISTANCE" AS NUMBER)) as valid_count,
    MIN(TRY_CAST("DISTANCE" AS NUMBER)) as min_value,
    MAX(TRY_CAST("DISTANCE" AS NUMBER)) as max_value,
    AVG(TRY_CAST("DISTANCE" AS NUMBER)) as avg_value
FROM STAGING_FLIGHTS_RAW
UNION ALL
SELECT 
    'DEPDELAY',
    COUNT(*),
    COUNT(TRY_CAST("DEPDELAY" AS NUMBER)),
    MIN(TRY_CAST("DEPDELAY" AS NUMBER)),
    MAX(TRY_CAST("DEPDELAY" AS NUMBER)),
    AVG(TRY_CAST("DEPDELAY" AS NUMBER))
FROM STAGING_FLIGHTS_RAW;

-- Check unique values in categorical fields
SELECT 
    "AIRLINE",
    "AIRLINENAME",
    COUNT(*) as flight_count
FROM STAGING_FLIGHTS_RAW
GROUP BY "AIRLINE", "AIRLINENAME"
ORDER BY flight_count DESC
LIMIT 20;

-- Summary report
SELECT 
    'Data Load Complete' as status,
    COUNT(*) as total_records,
    COUNT(DISTINCT "AIRLINE") as unique_airlines,
    COUNT(DISTINCT "ORIGAIRPORT") as unique_origin_airports,
    COUNT(DISTINCT "DESTAIRPORT") as unique_dest_airports
FROM STAGING_FLIGHTS_RAW;
