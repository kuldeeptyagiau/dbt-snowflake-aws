-- Flights Case Study - Phase 5: Final Validation & Testing
-- ========================================================

-- This script performs comprehensive validation to ensure all requirements are met
-- Run this after completing all previous phases

USE SCHEMA "candidate_1234";  -- Replace with your candidate number

-- =======================
-- REQUIREMENT VALIDATION
-- =======================

-- Step 1: Validate Required Tables Exist
-- ---------------------------------------
SELECT 
    'REQUIRED TABLES VALIDATION' as validation_type,
    CASE WHEN table_exists >= 4 THEN 'PASS' ELSE 'FAIL' END as result,
    table_exists as tables_found,
    4 as tables_required
FROM (
    SELECT COUNT(*) as table_exists
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'candidate_1234'  -- Update with your schema
      AND TABLE_NAME IN ('FACT_FLIGHTS', 'DIM_AIRLINE', 'DIM_AIRPORT', 'VW_FLIGHTS')
);

-- Step 2: Validate Required Columns in VW_FLIGHTS
-- ------------------------------------------------
SELECT 
    'VW_FLIGHTS REQUIRED COLUMNS' as validation_type,
    CASE WHEN required_cols >= 7 THEN 'PASS' ELSE 'FAIL' END as result,
    required_cols as columns_found,
    7 as columns_required,
    'TRANSACTIONID,DISTANCEGROUP,DEPDELAYGT15,NEXTDAYARR,AIRLINENAME,ORIGAIRPORTNAME,DESTAIRPORTNAME' as required_list
FROM (
    SELECT COUNT(*) as required_cols
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'VW_FLIGHTS' 
      AND TABLE_SCHEMA = 'candidate_1234'  -- Update with your schema
      AND COLUMN_NAME IN (
          'TRANSACTIONID', 'DISTANCEGROUP', 'DEPDELAYGT15', 
          'NEXTDAYARR', 'AIRLINENAME', 'ORIGAIRPORTNAME', 'DESTAIRPORTNAME'
      )
);

-- Step 3: Validate DISTANCEGROUP Format
-- --------------------------------------
SELECT 
    'DISTANCEGROUP FORMAT VALIDATION' as validation_type,
    CASE 
        WHEN invalid_formats = 0 THEN 'PASS'
        WHEN invalid_formats <= total_groups * 0.05 THEN 'WARNING'  -- Allow 5% margin
        ELSE 'FAIL'
    END as result,
    invalid_formats,
    total_groups,
    'Distance groups should end with "miles"' as requirement
FROM (
    SELECT 
        COUNT(*) as total_groups,
        COUNT(CASE WHEN "DISTANCEGROUP" NOT LIKE '%miles' AND "DISTANCEGROUP" != 'Unknown' THEN 1 END) as invalid_formats
    FROM (
        SELECT DISTINCT "DISTANCEGROUP" 
        FROM "VW_FLIGHTS" 
        WHERE "DISTANCEGROUP" IS NOT NULL
    )
);

-- Show sample DISTANCEGROUP values for verification
SELECT 
    'DISTANCEGROUP SAMPLES' as info_type,
    "DISTANCEGROUP",
    COUNT(*) as flight_count,
    MIN("DISTANCE") as min_distance,
    MAX("DISTANCE") as max_distance
FROM "VW_FLIGHTS"
WHERE "DISTANCEGROUP" IS NOT NULL
GROUP BY "DISTANCEGROUP"
ORDER BY min_distance
LIMIT 10;

-- Step 4: Validate DEPDELAYGT15 Logic
-- ------------------------------------
SELECT 
    'DEPDELAYGT15 LOGIC VALIDATION' as validation_type,
    CASE WHEN logic_errors = 0 THEN 'PASS' ELSE 'FAIL' END as result,
    logic_errors,
    total_records_with_delay,
    'Should be 1 when DEPDELAY > 15, 0 otherwise' as requirement
FROM (
    SELECT 
        COUNT(*) as total_records_with_delay,
        COUNT(CASE 
            WHEN ("DEPDELAY" > 15 AND "DEPDELAYGT15" != 1) OR 
                 ("DEPDELAY" <= 15 AND "DEPDELAYGT15" != 0) 
            THEN 1 
        END) as logic_errors
    FROM "VW_FLIGHTS" 
    WHERE "DEPDELAY" IS NOT NULL
);

-- Step 5: Validate NEXTDAYARR Logic  
-- ----------------------------------
SELECT 
    'NEXTDAYARR LOGIC VALIDATION' as validation_type,
    CASE WHEN suspicious_records <= valid_records * 0.1 THEN 'PASS' ELSE 'WARNING' END as result,
    suspicious_records,
    valid_records,
    'Next day arrival logic should be consistent with time differences' as requirement
FROM (
    SELECT 
        COUNT(*) as valid_records,
        COUNT(CASE 
            WHEN "NEXTDAYARR" = 0 AND "ARRTIME" < "DEPTIME" THEN 1
            WHEN "NEXTDAYARR" = 1 AND "ARRTIME" > "DEPTIME" THEN 1
        END) as suspicious_records
    FROM "VW_FLIGHTS"
    WHERE "DEPTIME" IS NOT NULL AND "ARRTIME" IS NOT NULL
);

-- Step 6: Validate Cleaned Names
-- -------------------------------
-- Check that airline names have been cleaned (no parentheses)
SELECT 
    'AIRLINE NAME CLEANING' as validation_type,
    CASE WHEN uncleaned_names = 0 THEN 'PASS' ELSE 'WARNING' END as result,
    uncleaned_names,
    total_airlines,
    'Airline names should not contain parentheses' as requirement
FROM (
    SELECT 
        COUNT(DISTINCT "AIRLINENAME") as total_airlines,
        COUNT(DISTINCT CASE WHEN "AIRLINENAME" LIKE '%(%' THEN "AIRLINENAME" END) as uncleaned_names
    FROM "VW_FLIGHTS"
    WHERE "AIRLINENAME" IS NOT NULL
);

-- Check that airport names have been cleaned  
SELECT 
    'AIRPORT NAME CLEANING' as validation_type,
    CASE WHEN uncleaned_names <= total_airports * 0.1 THEN 'PASS' ELSE 'WARNING' END as result,
    uncleaned_names,
    total_airports,
    'Airport names should not contain city, state suffixes' as requirement
FROM (
    SELECT 
        COUNT(DISTINCT "ORIGAIRPORTNAME") as total_airports,
        COUNT(DISTINCT CASE WHEN "ORIGAIRPORTNAME" LIKE '%, %' THEN "ORIGAIRPORTNAME" END) as uncleaned_names
    FROM "VW_FLIGHTS"
    WHERE "ORIGAIRPORTNAME" IS NOT NULL
);

-- =======================
-- DATA INTEGRITY CHECKS
-- =======================

-- Step 7: Check Data Completeness
-- --------------------------------
SELECT 
    'DATA COMPLETENESS CHECK' as validation_type,
    CASE WHEN completeness_score >= 80 THEN 'PASS' ELSE 'WARNING' END as result,
    ROUND(completeness_score, 2) as completeness_percentage,
    total_records,
    'Key fields should have >80% completeness' as requirement
FROM (
    SELECT 
        COUNT(*) as total_records,
        (COUNT("TRANSACTIONID") + COUNT("DISTANCE") + COUNT("AIRLINENAME") + COUNT("ORIGAIRPORTNAME")) / 
        (COUNT(*) * 4.0) * 100 as completeness_score
    FROM "VW_FLIGHTS"
);

-- Step 8: Check Referential Integrity
-- ------------------------------------
SELECT 
    'REFERENTIAL INTEGRITY' as validation_type,
    CASE WHEN orphaned_records = 0 THEN 'PASS' ELSE 'WARNING' END as result,
    orphaned_records,
    total_fact_records,
    'All fact records should have valid dimension references' as requirement
FROM (
    SELECT 
        COUNT(*) as total_fact_records,
        COUNT(CASE WHEN "AIRLINE_KEY" IS NULL OR "ORIGIN_AIRPORT_KEY" IS NULL OR "DEST_AIRPORT_KEY" IS NULL THEN 1 END) as orphaned_records
    FROM "FACT_FLIGHTS"
);

-- Step 9: Performance Validation
-- -------------------------------
-- Test query performance on the final view
SELECT 
    'PERFORMANCE TEST' as validation_type,
    'VIEW_QUERY' as test_type,
    COUNT(*) as records_returned,
    'Query executed successfully' as result
FROM "VW_FLIGHTS"
WHERE "FLIGHT_YEAR" IS NOT NULL
  AND "DISTANCEGROUP" IS NOT NULL
LIMIT 1000;

-- =======================
-- BUSINESS LOGIC VALIDATION
-- =======================

-- Step 10: Distance Group Distribution
-- -------------------------------------
SELECT 
    'DISTANCE GROUP DISTRIBUTION' as validation_type,
    'BUSINESS_LOGIC' as test_type,
    COUNT(DISTINCT "DISTANCEGROUP") as total_groups,
    COUNT(*) as total_flights,
    'Distance groups should show logical distribution' as requirement
FROM "VW_FLIGHTS"
WHERE "DISTANCEGROUP" IS NOT NULL AND "DISTANCEGROUP" != 'Unknown';

-- Step 11: Delay Flag Consistency
-- --------------------------------
SELECT 
    'DELAY FLAG CONSISTENCY' as validation_type,
    delay_flag,
    COUNT(*) as flight_count,
    ROUND(AVG("DEPDELAY"), 2) as avg_actual_delay,
    CASE 
        WHEN delay_flag = 1 AND AVG("DEPDELAY") > 15 THEN 'PASS'
        WHEN delay_flag = 0 AND AVG("DEPDELAY") <= 15 THEN 'PASS'
        ELSE 'CHECK'
    END as validation_result
FROM "VW_FLIGHTS"
WHERE "DEPDELAY" IS NOT NULL AND "DEPDELAYGT15" IS NOT NULL
GROUP BY "DEPDELAYGT15"
ORDER BY "DEPDELAYGT15";

-- =======================
-- FINAL SUMMARY REPORT
-- =======================

-- Step 12: Comprehensive Validation Summary
-- ------------------------------------------
CREATE OR REPLACE VIEW "VW_VALIDATION_SUMMARY" AS
WITH validation_results AS (
    SELECT 'Table Structure' as category, 
           CASE WHEN (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
                     WHERE TABLE_SCHEMA = 'candidate_1234' 
                     AND TABLE_NAME IN ('FACT_FLIGHTS', 'DIM_AIRLINE', 'DIM_AIRPORT', 'VW_FLIGHTS')) = 4 
                THEN 'PASS' ELSE 'FAIL' END as status
    
    UNION ALL
    
    SELECT 'Required Columns',
           CASE WHEN (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
                     WHERE TABLE_NAME = 'VW_FLIGHTS' AND TABLE_SCHEMA = 'candidate_1234'
                     AND COLUMN_NAME IN ('TRANSACTIONID', 'DISTANCEGROUP', 'DEPDELAYGT15', 
                                        'NEXTDAYARR', 'AIRLINENAME', 'ORIGAIRPORTNAME', 'DESTAIRPORTNAME')) = 7
                THEN 'PASS' ELSE 'FAIL' END
    
    UNION ALL
    
    SELECT 'Data Quality',
           CASE WHEN (SELECT COUNT(*) FROM "VW_FLIGHTS") > 0 THEN 'PASS' ELSE 'FAIL' END
    
    UNION ALL
    
    SELECT 'Business Logic',
           CASE WHEN (SELECT COUNT(*) FROM "VW_FLIGHTS" WHERE "DISTANCEGROUP" LIKE '%miles') > 0 
                THEN 'PASS' ELSE 'CHECK' END
)
SELECT 
    category,
    status,
    CASE 
        WHEN status = 'PASS' THEN '✓'
        WHEN status = 'FAIL' THEN '✗' 
        ELSE '⚠'
    END as indicator
FROM validation_results;

-- Display final summary
SELECT * FROM "VW_VALIDATION_SUMMARY";

-- Final execution summary
SELECT 
    'CASE STUDY VALIDATION COMPLETE' as status,
    CURRENT_TIMESTAMP as validation_time,
    (SELECT COUNT(*) FROM "VW_FLIGHTS") as final_view_records,
    (SELECT COUNT(*) FROM "FACT_FLIGHTS") as fact_table_records,
    (SELECT COUNT(*) FROM "DIM_AIRLINE") as airlines,
    (SELECT COUNT(*) FROM "DIM_AIRPORT") as airports,
    (SELECT COUNT(*) FROM "VW_VALIDATION_SUMMARY" WHERE status = 'PASS') as validations_passed,
    (SELECT COUNT(*) FROM "VW_VALIDATION_SUMMARY" WHERE status IN ('FAIL', 'CHECK')) as issues_found
;
