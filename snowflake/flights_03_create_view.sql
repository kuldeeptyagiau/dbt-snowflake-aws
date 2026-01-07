-- Flights Case Study - Phase 3: Create Final View
-- ================================================

-- Prerequisite: Run flights_02_dimensional_model.sql first
-- Assumes fact and dimension tables exist

USE SCHEMA "candidate_1234";  -- Replace with your candidate number

-- =======================
-- FINAL VIEW CREATION
-- =======================

-- Step 1: Create VW_FLIGHTS (Main Requirement)
-- ---------------------------------------------
CREATE OR REPLACE VIEW "VW_FLIGHTS" AS
SELECT 
    -- Required columns (DO NOT change these names per assignment)
    f."TRANSACTIONID",
    f."DISTANCEGROUP", 
    f."DEPDELAYGT15",
    f."NEXTDAYARR",
    a."AIRLINENAME_CLEAN" as "AIRLINENAME",  -- Cleaned airline name
    oa."AIRPORT_NAME_CLEAN" as "ORIGAIRPORTNAME",  -- Cleaned origin airport name
    da."AIRPORT_NAME_CLEAN" as "DESTAIRPORTNAME",  -- Cleaned destination airport name
    f."CANCELLED",
    
    -- Additional useful analytical columns
    -- Flight Details
    f."DISTANCE",
    f."DEPTIME",
    f."ARRTIME", 
    f."DEPDELAY",
    f."ARRDELAY",
    f."FLIGHTDATE",
    f."TAILNUM",
    
    -- Dimension Details for Analysis
    a."AIRLINE_CODE",
    a."AIRLINENAME" as "AIRLINENAME_ORIGINAL",  -- Keep original for reference
    oa."AIRPORT_CODE" as "ORIGAIRPORT_CODE",
    oa."AIRPORT_NAME" as "ORIGAIRPORTNAME_ORIGINAL",
    da."AIRPORT_CODE" as "DESTAIRPORT_CODE", 
    da."AIRPORT_NAME" as "DESTAIRPORTNAME_ORIGINAL",
    
    -- Date Dimension Details
    d."YEAR" as "FLIGHT_YEAR",
    d."MONTH" as "FLIGHT_MONTH",
    d."DAY" as "FLIGHT_DAY",
    d."MONTH_NAME" as "FLIGHT_MONTH_NAME",
    d."DAY_NAME" as "FLIGHT_DAY_NAME",
    d."QUARTER" as "FLIGHT_QUARTER",
    d."IS_WEEKEND",
    
    -- Additional Calculated Fields for Business Intelligence
    CASE 
        WHEN f."CANCELLED" = 1 THEN 'Cancelled'
        WHEN f."DEPDELAYGT15" = 1 THEN 'Delayed > 15 min'
        WHEN f."DEPDELAY" > 0 THEN 'Delayed <= 15 min'
        WHEN f."DEPDELAY" < 0 THEN 'Early'
        ELSE 'On Time'
    END as "FLIGHT_STATUS_CATEGORY",
    
    CASE 
        WHEN f."DISTANCE" <= 500 THEN 'Short Haul'
        WHEN f."DISTANCE" <= 1500 THEN 'Medium Haul'  
        ELSE 'Long Haul'
    END as "FLIGHT_RANGE_CATEGORY",
    
    -- Performance Metrics
    CASE 
        WHEN f."DEPDELAY" IS NULL THEN NULL
        WHEN f."DEPDELAY" <= 0 THEN 1
        ELSE 0
    END as "ON_TIME_DEPARTURE",
    
    CASE 
        WHEN f."ARRDELAY" IS NULL THEN NULL
        WHEN f."ARRDELAY" <= 0 THEN 1
        ELSE 0
    END as "ON_TIME_ARRIVAL",
    
    -- Time-based calculations
    CASE 
        WHEN f."DEPTIME" IS NOT NULL AND f."ARRTIME" IS NOT NULL THEN
            CASE 
                WHEN f."NEXTDAYARR" = 1 THEN 
                    TIMEDIFF('MINUTE', f."DEPTIME", f."ARRTIME") + 1440  -- Add 24 hours in minutes
                ELSE 
                    TIMEDIFF('MINUTE', f."DEPTIME", f."ARRTIME")
            END
        ELSE NULL
    END as "FLIGHT_DURATION_MINUTES",
    
    -- Data Quality Flags
    CASE WHEN f."DISTANCE" IS NULL THEN 1 ELSE 0 END as "MISSING_DISTANCE",
    CASE WHEN f."DEPTIME" IS NULL THEN 1 ELSE 0 END as "MISSING_DEPTIME", 
    CASE WHEN f."ARRTIME" IS NULL THEN 1 ELSE 0 END as "MISSING_ARRTIME",
    CASE WHEN f."DEPDELAY" IS NULL THEN 1 ELSE 0 END as "MISSING_DEPDELAY",
    CASE WHEN f."ARRDELAY" IS NULL THEN 1 ELSE 0 END as "MISSING_ARRDELAY"

FROM "FACT_FLIGHTS" f
    LEFT JOIN "DIM_AIRLINE" a ON f."AIRLINE_KEY" = a."AIRLINE_KEY"
    LEFT JOIN "DIM_AIRPORT" oa ON f."ORIGIN_AIRPORT_KEY" = oa."AIRPORT_KEY"
    LEFT JOIN "DIM_AIRPORT" da ON f."DEST_AIRPORT_KEY" = da."AIRPORT_KEY"
    LEFT JOIN "DIM_DATE" d ON f."DATE_KEY" = d."DATE_KEY";

-- =======================
-- VIEW VALIDATION
-- =======================

-- Step 2: Test the view
-- ---------------------

-- Basic count validation
SELECT COUNT(*) as total_records FROM "VW_FLIGHTS";

-- Test required columns are present with correct names
SELECT 
    "TRANSACTIONID",
    "DISTANCEGROUP", 
    "DEPDELAYGT15",
    "NEXTDAYARR", 
    "AIRLINENAME",
    "ORIGAIRPORTNAME",
    "DESTAIRPORTNAME",
    "CANCELLED"
FROM "VW_FLIGHTS" 
LIMIT 5;

-- Validate DISTANCEGROUP has correct format
SELECT 
    "DISTANCEGROUP",
    COUNT(*) as count,
    MIN("DISTANCE") as min_dist,
    MAX("DISTANCE") as max_dist
FROM "VW_FLIGHTS"
GROUP BY "DISTANCEGROUP"
ORDER BY min_dist;

-- Validate cleaned airline names
SELECT 
    "AIRLINE_CODE",
    "AIRLINENAME_ORIGINAL",
    "AIRLINENAME", 
    COUNT(*) as flights
FROM "VW_FLIGHTS"
WHERE "AIRLINE_CODE" IS NOT NULL
GROUP BY "AIRLINE_CODE", "AIRLINENAME_ORIGINAL", "AIRLINENAME"
ORDER BY flights DESC
LIMIT 10;

-- Validate cleaned airport names 
SELECT 
    "ORIGAIRPORT_CODE",
    "ORIGAIRPORTNAME_ORIGINAL", 
    "ORIGAIRPORTNAME",
    COUNT(*) as flights
FROM "VW_FLIGHTS" 
WHERE "ORIGAIRPORT_CODE" IS NOT NULL
GROUP BY "ORIGAIRPORT_CODE", "ORIGAIRPORTNAME_ORIGINAL", "ORIGAIRPORTNAME"
ORDER BY flights DESC
LIMIT 10;

-- =======================
-- BUSINESS INTELLIGENCE READY VIEWS
-- =======================

-- Step 3: Create Additional Views for Specific Analysis
-- ------------------------------------------------------

-- Summary view for executives
CREATE OR REPLACE VIEW "VW_FLIGHTS_SUMMARY" AS
SELECT 
    "FLIGHT_YEAR",
    "FLIGHT_MONTH", 
    "AIRLINE_CODE",
    "AIRLINENAME",
    COUNT(*) as "TOTAL_FLIGHTS",
    COUNT(CASE WHEN "CANCELLED" = 1 THEN 1 END) as "CANCELLED_FLIGHTS",
    COUNT(CASE WHEN "DEPDELAYGT15" = 1 THEN 1 END) as "DELAYED_FLIGHTS",
    AVG("DISTANCE") as "AVG_DISTANCE",
    AVG("DEPDELAY") as "AVG_DEPARTURE_DELAY",
    AVG("ARRDELAY") as "AVG_ARRIVAL_DELAY",
    SUM(CASE WHEN "ON_TIME_DEPARTURE" = 1 THEN 1 ELSE 0 END) / 
        COUNT(CASE WHEN "DEPDELAY" IS NOT NULL THEN 1 END) * 100 as "ON_TIME_DEPARTURE_PCT",
    SUM(CASE WHEN "ON_TIME_ARRIVAL" = 1 THEN 1 ELSE 0 END) / 
        COUNT(CASE WHEN "ARRDELAY" IS NOT NULL THEN 1 END) * 100 as "ON_TIME_ARRIVAL_PCT"
FROM "VW_FLIGHTS"
GROUP BY "FLIGHT_YEAR", "FLIGHT_MONTH", "AIRLINE_CODE", "AIRLINENAME";

-- Airport performance view
CREATE OR REPLACE VIEW "VW_AIRPORT_PERFORMANCE" AS
WITH airport_stats AS (
    -- Origin airport stats
    SELECT 
        "ORIGAIRPORT_CODE" as airport_code,
        "ORIGAIRPORTNAME" as airport_name,
        'ORIGIN' as airport_role,
        COUNT(*) as flights,
        AVG("DEPDELAY") as avg_delay,
        COUNT(CASE WHEN "CANCELLED" = 1 THEN 1 END) as cancelled_flights
    FROM "VW_FLIGHTS"
    WHERE "ORIGAIRPORT_CODE" IS NOT NULL
    GROUP BY "ORIGAIRPORT_CODE", "ORIGAIRPORTNAME"
    
    UNION ALL
    
    -- Destination airport stats  
    SELECT 
        "DESTAIRPORT_CODE" as airport_code,
        "DESTAIRPORTNAME" as airport_name, 
        'DESTINATION' as airport_role,
        COUNT(*) as flights,
        AVG("ARRDELAY") as avg_delay,
        COUNT(CASE WHEN "CANCELLED" = 1 THEN 1 END) as cancelled_flights
    FROM "VW_FLIGHTS"
    WHERE "DESTAIRPORT_CODE" IS NOT NULL
    GROUP BY "DESTAIRPORT_CODE", "DESTAIRPORTNAME"
)
SELECT 
    airport_code,
    airport_name,
    airport_role,
    flights,
    avg_delay,
    cancelled_flights,
    cancelled_flights / flights * 100 as cancellation_rate
FROM airport_stats;

-- =======================
-- FINAL VALIDATION
-- =======================

-- Step 4: Comprehensive validation report
-- ----------------------------------------
SELECT 
    'VIEW CREATION COMPLETE' as status,
    (SELECT COUNT(*) FROM "VW_FLIGHTS") as vw_flights_records,
    (SELECT COUNT(*) FROM "VW_FLIGHTS_SUMMARY") as summary_records,
    (SELECT COUNT(*) FROM "VW_AIRPORT_PERFORMANCE") as airport_perf_records,
    -- Verify all required columns exist
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = 'VW_FLIGHTS' AND COLUMN_NAME IN (
         'TRANSACTIONID', 'DISTANCEGROUP', 'DEPDELAYGT15', 
         'NEXTDAYARR', 'AIRLINENAME', 'ORIGAIRPORTNAME', 'DESTAIRPORTNAME'
     )) as required_columns_present
;
