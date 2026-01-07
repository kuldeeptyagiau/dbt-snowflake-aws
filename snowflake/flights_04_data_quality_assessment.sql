-- Flights Case Study - Phase 4: Data Quality Assessment
-- ======================================================

-- Prerequisite: Run previous scripts first
-- This script identifies and documents data quality issues

USE SCHEMA "candidate_1234";  -- Replace with your candidate number

-- =======================
-- DATA QUALITY ANALYSIS
-- =======================

-- Step 1: Missing Values Analysis
-- -------------------------------
CREATE OR REPLACE VIEW "VW_DATA_QUALITY_MISSING" AS
SELECT 
    'Missing Values Analysis' as analysis_type,
    COUNT(*) as total_records,
    
    -- Key identifiers
    COUNT(*) - COUNT("TRANSACTIONID") as missing_transaction_id,
    (COUNT(*) - COUNT("TRANSACTIONID")) / COUNT(*) * 100 as missing_transaction_id_pct,
    
    -- Flight identifiers  
    COUNT(*) - COUNT("AIRLINE_KEY") as missing_airline_key,
    (COUNT(*) - COUNT("AIRLINE_KEY")) / COUNT(*) * 100 as missing_airline_key_pct,
    
    COUNT(*) - COUNT("ORIGIN_AIRPORT_KEY") as missing_origin_airport,
    (COUNT(*) - COUNT("ORIGIN_AIRPORT_KEY")) / COUNT(*) * 100 as missing_origin_airport_pct,
    
    COUNT(*) - COUNT("DEST_AIRPORT_KEY") as missing_dest_airport, 
    (COUNT(*) - COUNT("DEST_AIRPORT_KEY")) / COUNT(*) * 100 as missing_dest_airport_pct,
    
    -- Flight measures
    COUNT(*) - COUNT("DISTANCE") as missing_distance,
    (COUNT(*) - COUNT("DISTANCE")) / COUNT(*) * 100 as missing_distance_pct,
    
    COUNT(*) - COUNT("DEPTIME") as missing_dep_time,
    (COUNT(*) - COUNT("DEPTIME")) / COUNT(*) * 100 as missing_dep_time_pct,
    
    COUNT(*) - COUNT("ARRTIME") as missing_arr_time,
    (COUNT(*) - COUNT("ARRTIME")) / COUNT(*) * 100 as missing_arr_time_pct,
    
    COUNT(*) - COUNT("DEPDELAY") as missing_dep_delay,
    (COUNT(*) - COUNT("DEPDELAY")) / COUNT(*) * 100 as missing_dep_delay_pct,
    
    COUNT(*) - COUNT("ARRDELAY") as missing_arr_delay,
    (COUNT(*) - COUNT("ARRDELAY")) / COUNT(*) * 100 as missing_arr_delay_pct,
    
    COUNT(*) - COUNT("FLIGHTDATE") as missing_flight_date,
    (COUNT(*) - COUNT("FLIGHTDATE")) / COUNT(*) * 100 as missing_flight_date_pct

FROM "FACT_FLIGHTS";

-- Display missing values analysis
SELECT * FROM "VW_DATA_QUALITY_MISSING";

-- Step 2: Data Range and Outlier Analysis
-- ----------------------------------------
CREATE OR REPLACE VIEW "VW_DATA_QUALITY_OUTLIERS" AS
WITH distance_stats AS (
    SELECT 
        COUNT(*) as total_flights,
        MIN("DISTANCE") as min_distance,
        MAX("DISTANCE") as max_distance,
        AVG("DISTANCE") as avg_distance,
        MEDIAN("DISTANCE") as median_distance,
        STDDEV("DISTANCE") as stddev_distance,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY "DISTANCE") as q1_distance,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY "DISTANCE") as q3_distance,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY "DISTANCE") as p95_distance,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY "DISTANCE") as p99_distance
    FROM "FACT_FLIGHTS" 
    WHERE "DISTANCE" IS NOT NULL
),
delay_stats AS (
    SELECT 
        MIN("DEPDELAY") as min_dep_delay,
        MAX("DEPDELAY") as max_dep_delay,
        AVG("DEPDELAY") as avg_dep_delay,
        MEDIAN("DEPDELAY") as median_dep_delay,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY "DEPDELAY") as p95_dep_delay,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY "DEPDELAY") as p99_dep_delay,
        
        MIN("ARRDELAY") as min_arr_delay,
        MAX("ARRDELAY") as max_arr_delay,
        AVG("ARRDELAY") as avg_arr_delay,
        MEDIAN("ARRDELAY") as median_arr_delay,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY "ARRDELAY") as p95_arr_delay,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY "ARRDELAY") as p99_arr_delay
    FROM "FACT_FLIGHTS"
    WHERE "DEPDELAY" IS NOT NULL OR "ARRDELAY" IS NOT NULL
)
SELECT 
    'Data Range Analysis' as analysis_type,
    -- Distance statistics
    d.min_distance, d.max_distance, d.avg_distance, d.median_distance,
    d.q1_distance, d.q3_distance, d.p95_distance, d.p99_distance,
    -- Delay statistics  
    s.min_dep_delay, s.max_dep_delay, s.avg_dep_delay, s.median_dep_delay,
    s.p95_dep_delay, s.p99_dep_delay,
    s.min_arr_delay, s.max_arr_delay, s.avg_arr_delay, s.median_arr_delay,
    s.p95_arr_delay, s.p99_arr_delay
FROM distance_stats d
CROSS JOIN delay_stats s;

-- Display outlier analysis
SELECT * FROM "VW_DATA_QUALITY_OUTLIERS";

-- Step 3: Identify Specific Data Quality Issues
-- ----------------------------------------------

-- Unrealistic flight distances (likely data entry errors)
SELECT 
    'Unrealistic Distances' as issue_type,
    COUNT(*) as affected_records,
    MIN("DISTANCE") as min_value,
    MAX("DISTANCE") as max_value
FROM "FACT_FLIGHTS"
WHERE "DISTANCE" < 10 OR "DISTANCE" > 5000;  -- Adjust thresholds as needed

-- Show specific examples of unrealistic distances
SELECT 
    "TRANSACTIONID",
    "DISTANCE",
    "AIRLINE_KEY",
    "ORIGIN_AIRPORT_KEY", 
    "DEST_AIRPORT_KEY"
FROM "FACT_FLIGHTS"
WHERE "DISTANCE" < 10 OR "DISTANCE" > 5000
LIMIT 10;

-- Extreme delay values (potential outliers)
SELECT 
    'Extreme Delays' as issue_type,
    'DEPARTURE' as delay_type,
    COUNT(*) as affected_records,
    MIN("DEPDELAY") as min_delay,
    MAX("DEPDELAY") as max_delay
FROM "FACT_FLIGHTS"
WHERE "DEPDELAY" < -120 OR "DEPDELAY" > 1440  -- More than 2 hours early or 24 hours delayed

UNION ALL

SELECT 
    'Extreme Delays',
    'ARRIVAL', 
    COUNT(*),
    MIN("ARRDELAY"),
    MAX("ARRDELAY")
FROM "FACT_FLIGHTS"
WHERE "ARRDELAY" < -120 OR "ARRDELAY" > 1440;

-- Invalid time combinations
SELECT 
    'Invalid Time Combinations' as issue_type,
    COUNT(*) as affected_records
FROM "FACT_FLIGHTS"
WHERE "NEXTDAYARR" = 0 
  AND "ARRTIME" IS NOT NULL 
  AND "DEPTIME" IS NOT NULL
  AND "ARRTIME" <= "DEPTIME";  -- Arrival same time or before departure on same day

-- Step 4: Business Logic Violations
-- ----------------------------------

-- Cancelled flights with delay information (might be valid, but worth noting)
SELECT 
    'Cancelled flights with delays' as issue_type,
    COUNT(*) as affected_records,
    AVG("DEPDELAY") as avg_dep_delay,
    AVG("ARRDELAY") as avg_arr_delay
FROM "FACT_FLIGHTS"
WHERE "CANCELLED" = 1 
  AND ("DEPDELAY" IS NOT NULL OR "ARRDELAY" IS NOT NULL);

-- Flights with arrival delay but no departure delay (unusual but possible)
SELECT 
    'Arrival delay without departure delay' as issue_type,
    COUNT(*) as affected_records
FROM "FACT_FLIGHTS"
WHERE "ARRDELAY" > 15 
  AND ("DEPDELAY" IS NULL OR "DEPDELAY" <= 0)
  AND "CANCELLED" = 0;

-- Step 5: Data Consistency Checks
-- --------------------------------

-- Check for duplicate transaction IDs
WITH duplicate_transactions AS (
    SELECT 
        "TRANSACTIONID",
        COUNT(*) as occurrence_count
    FROM "FACT_FLIGHTS"
    WHERE "TRANSACTIONID" IS NOT NULL
    GROUP BY "TRANSACTIONID"
    HAVING COUNT(*) > 1
)
SELECT 
    'Duplicate Transaction IDs' as issue_type,
    COUNT(*) as unique_duplicated_ids,
    SUM(occurrence_count) as total_duplicate_records
FROM duplicate_transactions;

-- Show examples of duplicates
SELECT f.*
FROM "FACT_FLIGHTS" f
INNER JOIN (
    SELECT "TRANSACTIONID"
    FROM "FACT_FLIGHTS" 
    WHERE "TRANSACTIONID" IS NOT NULL
    GROUP BY "TRANSACTIONID"
    HAVING COUNT(*) > 1
) dups ON f."TRANSACTIONID" = dups."TRANSACTIONID"
ORDER BY f."TRANSACTIONID"
LIMIT 20;

-- Step 6: Data Quality Score Calculation
-- ---------------------------------------
CREATE OR REPLACE VIEW "VW_DATA_QUALITY_SCORE" AS
WITH quality_metrics AS (
    SELECT 
        COUNT(*) as total_records,
        
        -- Completeness scores (higher is better)
        COUNT("TRANSACTIONID") / COUNT(*) * 100 as transactionid_completeness,
        COUNT("DISTANCE") / COUNT(*) * 100 as distance_completeness,
        COUNT("DEPTIME") / COUNT(*) * 100 as deptime_completeness,
        COUNT("ARRTIME") / COUNT(*) * 100 as arrtime_completeness,
        COUNT("DEPDELAY") / COUNT(*) * 100 as depdelay_completeness,
        COUNT("ARRDELAY") / COUNT(*) * 100 as arrdelay_completeness,
        
        -- Validity scores (percentage of valid values)
        COUNT(CASE WHEN "DISTANCE" BETWEEN 10 AND 5000 THEN 1 END) / 
            COUNT("DISTANCE") * 100 as distance_validity,
        
        COUNT(CASE WHEN "DEPDELAY" BETWEEN -120 AND 1440 THEN 1 END) /
            COUNT("DEPDELAY") * 100 as depdelay_validity,
            
        COUNT(CASE WHEN "ARRDELAY" BETWEEN -120 AND 1440 THEN 1 END) /
            COUNT("ARRDELAY") * 100 as arrdelay_validity,
            
        -- Consistency scores
        COUNT(CASE WHEN "NEXTDAYARR" = 1 OR "ARRTIME" > "DEPTIME" OR 
                           "ARRTIME" IS NULL OR "DEPTIME" IS NULL THEN 1 END) /
            COUNT(*) * 100 as time_consistency
            
    FROM "FACT_FLIGHTS"
)
SELECT 
    'Data Quality Summary' as metric_category,
    total_records,
    
    -- Overall completeness (average of key fields)
    ROUND((transactionid_completeness + distance_completeness + 
           deptime_completeness + arrtime_completeness) / 4, 2) as overall_completeness_score,
    
    -- Overall validity (average of numeric validations)
    ROUND((distance_validity + depdelay_validity + arrdelay_validity) / 3, 2) as overall_validity_score,
    
    -- Individual scores
    ROUND(transactionid_completeness, 2) as transactionid_completeness,
    ROUND(distance_completeness, 2) as distance_completeness,
    ROUND(distance_validity, 2) as distance_validity,
    ROUND(depdelay_validity, 2) as depdelay_validity,
    ROUND(arrdelay_validity, 2) as arrdelay_validity,
    ROUND(time_consistency, 2) as time_consistency_score

FROM quality_metrics;

-- Display quality score
SELECT * FROM "VW_DATA_QUALITY_SCORE";

-- Step 7: Data Quality Issues Summary for Presentation
-- -----------------------------------------------------
CREATE OR REPLACE VIEW "VW_DATA_QUALITY_SUMMARY" AS
SELECT 
    'COMPLETENESS' as category,
    'Missing Transaction IDs' as issue,
    (SELECT missing_transaction_id FROM "VW_DATA_QUALITY_MISSING") as affected_records,
    'HIGH' as severity,
    'Critical for data integrity' as impact,
    'Exclude from analysis or create synthetic IDs' as recommended_action

UNION ALL SELECT 
    'COMPLETENESS',
    'Missing Distance Values', 
    (SELECT missing_distance FROM "VW_DATA_QUALITY_MISSING"),
    'MEDIUM',
    'Affects distance-based calculations',
    'Impute using route averages or exclude'

UNION ALL SELECT 
    'COMPLETENESS',
    'Missing Time Information',
    (SELECT missing_dep_time + missing_arr_time FROM "VW_DATA_QUALITY_MISSING"),
    'MEDIUM', 
    'Affects punctuality analysis',
    'Mark as unknown, exclude from time analysis'

UNION ALL SELECT 
    'VALIDITY',
    'Unrealistic Distances',
    (SELECT COUNT(*) FROM "FACT_FLIGHTS" WHERE "DISTANCE" < 10 OR "DISTANCE" > 5000),
    'HIGH',
    'Data accuracy concerns',
    'Investigate source, correct if possible'

UNION ALL SELECT 
    'VALIDITY', 
    'Extreme Delay Values',
    (SELECT COUNT(*) FROM "FACT_FLIGHTS" 
     WHERE "DEPDELAY" < -120 OR "DEPDELAY" > 1440 
        OR "ARRDELAY" < -120 OR "ARRDELAY" > 1440),
    'MEDIUM',
    'May skew statistical analysis', 
    'Cap extreme values or treat as outliers'

UNION ALL SELECT 
    'CONSISTENCY',
    'Time Logic Violations',
    (SELECT COUNT(*) FROM "FACT_FLIGHTS" 
     WHERE "NEXTDAYARR" = 0 AND "ARRTIME" <= "DEPTIME"),
    'MEDIUM',
    'Business logic inconsistency',
    'Recalculate NEXTDAYARR flag'

ORDER BY 
    CASE category 
        WHEN 'COMPLETENESS' THEN 1 
        WHEN 'VALIDITY' THEN 2 
        WHEN 'CONSISTENCY' THEN 3 
    END,
    CASE severity 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;

-- Display comprehensive summary
SELECT * FROM "VW_DATA_QUALITY_SUMMARY";

-- Final summary for presentation
SELECT 
    'DATA QUALITY ASSESSMENT COMPLETE' as status,
    CURRENT_TIMESTAMP as assessment_time,
    (SELECT total_records FROM "VW_DATA_QUALITY_SCORE") as records_analyzed,
    (SELECT overall_completeness_score FROM "VW_DATA_QUALITY_SCORE") as completeness_score,
    (SELECT overall_validity_score FROM "VW_DATA_QUALITY_SCORE") as validity_score,
    (SELECT COUNT(*) FROM "VW_DATA_QUALITY_SUMMARY" WHERE severity = 'HIGH') as high_priority_issues,
    (SELECT COUNT(*) FROM "VW_DATA_QUALITY_SUMMARY" WHERE severity = 'MEDIUM') as medium_priority_issues;
