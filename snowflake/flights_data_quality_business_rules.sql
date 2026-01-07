-- DATA QUALITY ASSESSMENT & BUSINESS RULES
-- =========================================
-- Flight Data Quality Issues Analysis and Resolution
-- Based on sample data analysis from flights_data_exploration_001.csv

USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00395;

-- ====================
-- 1. DATA QUALITY ISSUES IDENTIFICATION
-- ====================

-- Issue 1: Inconsistent Boolean Values
-- Problem: CANCELLED and DIVERTED fields contain mixed formats
-- Sample values found: 'True', 'False', '1', '0', 'Y', 'N', 'F', 'T'
SELECT 
    'Boolean Inconsistencies' AS "ISSUE_TYPE",
    COUNT(*) AS "TOTAL_RECORDS",
    COUNT(DISTINCT "CANCELLED") AS "CANCELLED_VARIATIONS",
    COUNT(DISTINCT "DIVERTED") AS "DIVERTED_VARIATIONS"
FROM "STAGING_FLIGHTS_RAW";

-- Show actual boolean variations
SELECT 
    "CANCELLED",
    "DIVERTED", 
    COUNT(*) AS "RECORD_COUNT"
FROM "STAGING_FLIGHTS_RAW"
GROUP BY "CANCELLED", "DIVERTED"
ORDER BY "RECORD_COUNT" DESC;

-- Issue 2: Contaminated Text Fields
-- Problem: Airline and airport names contain concatenated codes/descriptions
-- Examples: "DL: Delta Air Lines Inc.", "CharlestonSC: Charleston AFB/International"
SELECT 
    'Text Field Contamination' AS "ISSUE_TYPE",
    COUNT(CASE WHEN "AIRLINENAME" LIKE '%:%' THEN 1 END) AS "CONTAMINATED_AIRLINES",
    COUNT(CASE WHEN "ORIGAIRPORTNAME" LIKE '%:%' THEN 1 END) AS "CONTAMINATED_ORIGIN_AIRPORTS",
    COUNT(CASE WHEN "DESTAIRPORTNAME" LIKE '%:%' THEN 1 END) AS "CONTAMINATED_DEST_AIRPORTS",
    COUNT(*) AS "TOTAL_RECORDS"
FROM "STAGING_FLIGHTS_RAW";

-- Issue 3: Time Format Complexity  
-- Problem: Times stored as integers (1134 = 11:34 AM)
SELECT 
    'Time Format Issues' AS "ISSUE_TYPE",
    COUNT(CASE WHEN LENGTH("DEPTIME") BETWEEN 3 AND 4 AND "DEPTIME" NOT LIKE '%:%' THEN 1 END) AS "INTEGER_FORMAT_TIMES",
    COUNT(CASE WHEN "DEPTIME" IS NULL AND "CANCELLED" != '1' AND "CANCELLED" != 'True' THEN 1 END) AS "MISSING_TIMES_NON_CANCELLED",
    COUNT(*) AS "TOTAL_RECORDS"
FROM "STAGING_FLIGHTS_RAW";

-- Issue 4: Tail Number Standardization Issues
-- Problem: Various non-standard formats (-N963D, NKNO, UNKNOW, blanks)
SELECT 
    'Tail Number Quality' AS "ISSUE_TYPE",
    COUNT(CASE WHEN "TAILNUM" IS NULL OR TRIM("TAILNUM") = '' THEN 1 END) AS "MISSING_TAILNUM",
    COUNT(CASE WHEN "TAILNUM" LIKE 'UNKNOW%' THEN 1 END) AS "UNKNOWN_TAILNUM",
    COUNT(CASE WHEN "TAILNUM" LIKE '-%' THEN 1 END) AS "INVALID_PREFIX_TAILNUM",
    COUNT(CASE WHEN LENGTH("TAILNUM") < 3 AND "TAILNUM" IS NOT NULL THEN 1 END) AS "TOO_SHORT_TAILNUM",
    COUNT(*) AS "TOTAL_RECORDS"
FROM "STAGING_FLIGHTS_RAW";

-- Issue 5: Distance Format Inconsistencies
-- Problem: "259 miles" vs numeric values
SELECT 
    'Distance Format Issues' AS "ISSUE_TYPE",
    COUNT(CASE WHEN "DISTANCE" LIKE '%miles%' THEN 1 END) AS "TEXT_FORMAT_DISTANCE",
    COUNT(CASE WHEN TRY_CAST("DISTANCE" AS NUMBER) IS NULL AND "DISTANCE" IS NOT NULL THEN 1 END) AS "NON_NUMERIC_DISTANCE",
    COUNT(*) AS "TOTAL_RECORDS"
FROM "STAGING_FLIGHTS_RAW";

-- ====================
-- 2. BUSINESS RULES IMPLEMENTATION
-- ====================

-- Rule 1: Standardize Boolean Values
CREATE OR REPLACE VIEW "VW_STANDARDIZED_BOOLEANS" AS
SELECT 
    "TRANSACTIONID",
    -- Standardize CANCELLED field
    CASE 
        WHEN UPPER(TRIM("CANCELLED")) IN ('TRUE', '1', 'T', 'Y', 'YES') THEN 1
        WHEN UPPER(TRIM("CANCELLED")) IN ('FALSE', '0', 'F', 'N', 'NO') THEN 0
        ELSE NULL
    END AS "CANCELLED_STD",
    
    -- Standardize DIVERTED field  
    CASE 
        WHEN UPPER(TRIM("DIVERTED")) IN ('TRUE', '1', 'T', 'Y', 'YES') THEN 1
        WHEN UPPER(TRIM("DIVERTED")) IN ('FALSE', '0', 'F', 'N', 'NO') THEN 0
        ELSE NULL
    END AS "DIVERTED_STD",
    
    -- Original values for comparison
    "CANCELLED" AS "CANCELLED_ORIGINAL",
    "DIVERTED" AS "DIVERTED_ORIGINAL"
FROM "STAGING_FLIGHTS_RAW";

-- Rule 2: Clean Text Fields
CREATE OR REPLACE VIEW "VW_CLEANED_TEXT_FIELDS" AS
SELECT 
    "TRANSACTIONID",
    
    -- Clean airline name by removing code prefix
    CASE 
        WHEN "AIRLINENAME" LIKE '%:%' 
        THEN TRIM(SPLIT_PART("AIRLINENAME", ':', 2))
        ELSE TRIM("AIRLINENAME")
    END AS "AIRLINENAME_CLEAN",
    
    -- Clean origin airport name
    CASE 
        WHEN "ORIGAIRPORTNAME" LIKE '%:%' 
        THEN TRIM(SPLIT_PART("ORIGAIRPORTNAME", ':', 2))
        ELSE TRIM("ORIGAIRPORTNAME")
    END AS "ORIGAIRPORTNAME_CLEAN",
    
    -- Clean destination airport name
    CASE 
        WHEN "DESTAIRPORTNAME" LIKE '%:%' 
        THEN TRIM(SPLIT_PART("DESTAIRPORTNAME", ':', 2))
        ELSE TRIM("DESTAIRPORTNAME")
    END AS "DESTAIRPORTNAME_CLEAN",
    
    -- Original values for comparison
    "AIRLINENAME" AS "AIRLINENAME_ORIGINAL",
    "ORIGAIRPORTNAME" AS "ORIGAIRPORTNAME_ORIGINAL", 
    "DESTAIRPORTNAME" AS "DESTAIRPORTNAME_ORIGINAL"
FROM "STAGING_FLIGHTS_RAW";

-- Rule 3: Time Format Standardization
CREATE OR REPLACE VIEW "VW_STANDARDIZED_TIMES" AS
SELECT 
    "TRANSACTIONID",
    
    -- Convert HHMM integer format to proper TIME
    TRY_CAST(
        CASE 
            WHEN LENGTH(TRIM("DEPTIME")) <= 4 AND "DEPTIME" IS NOT NULL AND "DEPTIME" != ''
            THEN TIME_FROM_PARTS(
                FLOOR(TRY_CAST("DEPTIME" AS INTEGER) / 100),
                MOD(TRY_CAST("DEPTIME" AS INTEGER), 100),
                0
            )
        END AS TIME
    ) AS "DEPTIME_STD",
    
    TRY_CAST(
        CASE 
            WHEN LENGTH(TRIM("ARRTIME")) <= 4 AND "ARRTIME" IS NOT NULL AND "ARRTIME" != ''
            THEN TIME_FROM_PARTS(
                FLOOR(TRY_CAST("ARRTIME" AS INTEGER) / 100),
                MOD(TRY_CAST("ARRTIME" AS INTEGER), 100),
                0
            )
        END AS TIME
    ) AS "ARRTIME_STD",
    
    TRY_CAST(
        CASE 
            WHEN LENGTH(TRIM("CRSDEPTIME")) <= 4 AND "CRSDEPTIME" IS NOT NULL AND "CRSDEPTIME" != ''
            THEN TIME_FROM_PARTS(
                FLOOR(TRY_CAST("CRSDEPTIME" AS INTEGER) / 100),
                MOD(TRY_CAST("CRSDEPTIME" AS INTEGER), 100),
                0
            )
        END AS TIME
    ) AS "CRSDEPTIME_STD",
    
    TRY_CAST(
        CASE 
            WHEN LENGTH(TRIM("CRSARRTIME")) <= 4 AND "CRSARRTIME" IS NOT NULL AND "CRSARRTIME" != ''
            THEN TIME_FROM_PARTS(
                FLOOR(TRY_CAST("CRSARRTIME" AS INTEGER) / 100),
                MOD(TRY_CAST("CRSARRTIME" AS INTEGER), 100),
                0
            )
        END AS TIME
    ) AS "CRSARRTIME_STD",
    
    -- Original values
    "DEPTIME" AS "DEPTIME_ORIGINAL",
    "ARRTIME" AS "ARRTIME_ORIGINAL",
    "CRSDEPTIME" AS "CRSDEPTIME_ORIGINAL",
    "CRSARRTIME" AS "CRSARRTIME_ORIGINAL"
FROM "STAGING_FLIGHTS_RAW";

-- Rule 4: Tail Number Quality Assessment
CREATE OR REPLACE VIEW "VW_TAILNUM_QUALITY" AS
SELECT 
    "TRANSACTIONID",
    "TAILNUM",
    
    CASE 
        WHEN "TAILNUM" IS NULL OR TRIM("TAILNUM") = '' THEN 'MISSING'
        WHEN UPPER("TAILNUM") = 'UNKNOW' THEN 'UNKNOWN'
        WHEN "TAILNUM" LIKE '-%' THEN 'INVALID_PREFIX'
        WHEN "TAILNUM" REGEXP '^N[0-9A-Z]{1,5}[A-Z]{0,2}$' THEN 'VALID_US_FORMAT'
        WHEN LENGTH("TAILNUM") < 3 THEN 'TOO_SHORT'
        WHEN LENGTH("TAILNUM") > 8 THEN 'TOO_LONG'
        ELSE 'NON_STANDARD'
    END AS "TAILNUM_QUALITY_FLAG",
    
    -- Business decision: Keep original data but flag quality
    CASE 
        WHEN "TAILNUM" IS NULL OR TRIM("TAILNUM") = '' THEN 0
        WHEN UPPER("TAILNUM") = 'UNKNOW' THEN 0
        WHEN "TAILNUM" LIKE '-%' THEN 0
        WHEN "TAILNUM" REGEXP '^N[0-9A-Z]{1,5}[A-Z]{0,2}$' THEN 1
        ELSE 0.5  -- Uncertain quality
    END AS "TAILNUM_QUALITY_SCORE"
FROM "STAGING_FLIGHTS_RAW";

-- Rule 5: Distance Standardization
CREATE OR REPLACE VIEW "VW_STANDARDIZED_DISTANCE" AS
SELECT 
    "TRANSACTIONID",
    "DISTANCE" AS "DISTANCE_ORIGINAL",
    
    -- Extract numeric distance value
    TRY_CAST(REGEXP_SUBSTR("DISTANCE", '\\d+') AS INTEGER) AS "DISTANCE_MILES",
    
    -- Quality flag
    CASE 
        WHEN "DISTANCE" IS NULL THEN 'MISSING'
        WHEN "DISTANCE" LIKE '%miles%' THEN 'TEXT_FORMAT'
        WHEN TRY_CAST("DISTANCE" AS NUMBER) IS NOT NULL THEN 'NUMERIC_FORMAT'
        ELSE 'INVALID_FORMAT'
    END AS "DISTANCE_FORMAT_TYPE"
FROM "STAGING_FLIGHTS_RAW";

-- ====================
-- 3. BUSINESS VALIDATION RULES
-- ====================

-- Validation Rule 1: Cancelled Flight Data Consistency
-- Business Rule: Cancelled flights should have missing operational time data
CREATE OR REPLACE VIEW "VW_CANCELLED_FLIGHT_VALIDATION" AS
SELECT 
    "TRANSACTIONID",
    "CANCELLED",
    "DEPTIME",
    "ARRTIME",
    "DEPDELAY",
    "ARRDELAY",
    
    CASE 
        WHEN "CANCELLED" IN ('1', 'True', 'T', 'Y') 
             AND ("DEPTIME" IS NOT NULL OR "ARRTIME" IS NOT NULL) 
        THEN 'INCONSISTENT_CANCELLED_WITH_TIMES'
        
        WHEN "CANCELLED" NOT IN ('1', 'True', 'T', 'Y') 
             AND ("DEPTIME" IS NULL AND "ARRTIME" IS NULL)
        THEN 'NON_CANCELLED_MISSING_TIMES'
        
        ELSE 'CONSISTENT'
    END AS "CANCELLATION_CONSISTENCY",
    
    -- Flag for review
    CASE 
        WHEN "CANCELLED" IN ('1', 'True', 'T', 'Y') 
             AND ("DEPTIME" IS NOT NULL OR "ARRTIME" IS NOT NULL) 
        THEN 1
        WHEN "CANCELLED" NOT IN ('1', 'True', 'T', 'Y') 
             AND ("DEPTIME" IS NULL AND "ARRTIME" IS NULL)
        THEN 1
        ELSE 0
    END AS "REQUIRES_REVIEW"
FROM "STAGING_FLIGHTS_RAW";

-- Validation Rule 2: Delay Logic Consistency  
-- Business Rule: Negative delays indicate early departure/arrival
CREATE OR REPLACE VIEW "VW_DELAY_VALIDATION" AS
SELECT 
    "TRANSACTIONID",
    "DEPDELAY",
    "ARRDELAY",
    "CANCELLED",
    
    -- Departure delay validation
    CASE 
        WHEN TRY_CAST("DEPDELAY" AS INTEGER) IS NULL AND "CANCELLED" NOT IN ('1', 'True') 
        THEN 'INVALID_DEPDELAY_NON_CANCELLED'
        WHEN TRY_CAST("DEPDELAY" AS INTEGER) < -60 
        THEN 'EXTREMELY_EARLY_DEPARTURE'
        WHEN TRY_CAST("DEPDELAY" AS INTEGER) > 480  -- 8 hours
        THEN 'EXTREMELY_DELAYED_DEPARTURE'
        ELSE 'REASONABLE_DEPDELAY'
    END AS "DEPDELAY_VALIDATION",
    
    -- Arrival delay validation
    CASE 
        WHEN TRY_CAST("ARRDELAY" AS INTEGER) IS NULL AND "CANCELLED" NOT IN ('1', 'True')
        THEN 'INVALID_ARRDELAY_NON_CANCELLED'
        WHEN TRY_CAST("ARRDELAY" AS INTEGER) < -120  -- 2 hours early
        THEN 'EXTREMELY_EARLY_ARRIVAL'
        WHEN TRY_CAST("ARRDELAY" AS INTEGER) > 600   -- 10 hours late
        THEN 'EXTREMELY_DELAYED_ARRIVAL'
        ELSE 'REASONABLE_ARRDELAY'
    END AS "ARRDELAY_VALIDATION"
FROM "STAGING_FLIGHTS_RAW";

-- Validation Rule 3: Historical Date Context
-- Business Rule: Handle sensitive historical periods (9/11/2001)
CREATE OR REPLACE VIEW "VW_HISTORICAL_CONTEXT" AS
SELECT 
    "TRANSACTIONID",
    TRY_CAST("FLIGHTDATE" AS DATE) AS "FLIGHT_DATE",
    
    CASE 
        WHEN TRY_CAST("FLIGHTDATE" AS DATE) BETWEEN '2001-09-11' AND '2001-09-20' 
        THEN 'POST_911_SENSITIVE_PERIOD'
        WHEN TRY_CAST("FLIGHTDATE" AS DATE) < '1990-01-01' 
        THEN 'VERY_HISTORICAL'
        WHEN TRY_CAST("FLIGHTDATE" AS DATE) > CURRENT_DATE() 
        THEN 'FUTURE_DATE_ERROR'
        ELSE 'NORMAL_PERIOD'
    END AS "HISTORICAL_CONTEXT",
    
    -- Special handling flag
    CASE 
        WHEN TRY_CAST("FLIGHTDATE" AS DATE) BETWEEN '2001-09-11' AND '2001-09-20' THEN 1
        ELSE 0
    END AS "IS_SENSITIVE_PERIOD"
FROM "STAGING_FLIGHTS_RAW";

-- ====================
-- 4. DATA QUALITY SCORECARD
-- ====================

CREATE OR REPLACE VIEW "VW_DATA_QUALITY_SCORECARD" AS
WITH quality_assessment AS (
    SELECT 
        "TRANSACTIONID",
        
        -- Boolean quality (1 = good, 0 = poor)
        CASE WHEN "CANCELLED" IN ('1', '0', 'True', 'False') THEN 1 ELSE 0 END AS "BOOL_QUALITY",
        
        -- Text quality
        CASE WHEN "AIRLINENAME" NOT LIKE '%:%' THEN 1 ELSE 0 END AS "AIRLINE_QUALITY",
        CASE WHEN "ORIGAIRPORTNAME" NOT LIKE '%:%' THEN 1 ELSE 0 END AS "AIRPORT_QUALITY",
        
        -- Time quality  
        CASE WHEN TRY_CAST("DEPTIME" AS TIME) IS NOT NULL OR "CANCELLED" IN ('1', 'True') THEN 1 ELSE 0 END AS "TIME_QUALITY",
        
        -- Tailnum quality
        CASE 
            WHEN "TAILNUM" REGEXP '^N[0-9A-Z]{1,5}[A-Z]{0,2}$' THEN 1
            WHEN "TAILNUM" IS NULL OR "TAILNUM" = 'UNKNOW' THEN 0.5
            ELSE 0 
        END AS "TAILNUM_QUALITY",
        
        -- Distance quality
        CASE WHEN TRY_CAST(REGEXP_SUBSTR("DISTANCE", '\\d+') AS INTEGER) IS NOT NULL THEN 1 ELSE 0 END AS "DISTANCE_QUALITY"
        
    FROM "STAGING_FLIGHTS_RAW"
)
SELECT 
    "TRANSACTIONID",
    
    -- Individual quality scores
    "BOOL_QUALITY",
    "AIRLINE_QUALITY", 
    "AIRPORT_QUALITY",
    "TIME_QUALITY",
    "TAILNUM_QUALITY",
    "DISTANCE_QUALITY",
    
    -- Overall quality score (0-1 scale)
    ("BOOL_QUALITY" + "AIRLINE_QUALITY" + "AIRPORT_QUALITY" + 
     "TIME_QUALITY" + "TAILNUM_QUALITY" + "DISTANCE_QUALITY") / 6.0 AS "OVERALL_QUALITY_SCORE",
    
    -- Quality category
    CASE 
        WHEN ("BOOL_QUALITY" + "AIRLINE_QUALITY" + "AIRPORT_QUALITY" + 
              "TIME_QUALITY" + "TAILNUM_QUALITY" + "DISTANCE_QUALITY") / 6.0 >= 0.9 THEN 'EXCELLENT'
        WHEN ("BOOL_QUALITY" + "AIRLINE_QUALITY" + "AIRPORT_QUALITY" + 
              "TIME_QUALITY" + "TAILNUM_QUALITY" + "DISTANCE_QUALITY") / 6.0 >= 0.7 THEN 'GOOD'
        WHEN ("BOOL_QUALITY" + "AIRLINE_QUALITY" + "AIRPORT_QUALITY" + 
              "TIME_QUALITY" + "TAILNUM_QUALITY" + "DISTANCE_QUALITY") / 6.0 >= 0.5 THEN 'FAIR'
        ELSE 'POOR'
    END AS "QUALITY_CATEGORY"
FROM quality_assessment;

-- ====================
-- 5. BUSINESS RESOLUTION ACTIONS
-- ====================

-- Resolution 1: Apply Data Corrections
CREATE OR REPLACE TABLE "STAGING_FLIGHTS_CLEANED" AS
SELECT 
    s."TRANSACTIONID",
    TRY_CAST(s."FLIGHTDATE" AS DATE) AS "FLIGHTDATE",
    s."AIRLINECODE",
    ct."AIRLINENAME_CLEAN" AS "AIRLINENAME",
    s."TAILNUM",
    tq."TAILNUM_QUALITY_FLAG",
    TRY_CAST(s."FLIGHTNUM" AS INTEGER) AS "FLIGHTNUM",
    s."ORIGINAIRPORTCODE",
    ct."ORIGAIRPORTNAME_CLEAN" AS "ORIGAIRPORTNAME",
    s."DESTAIRPORTCODE", 
    ct."DESTAIRPORTNAME_CLEAN" AS "DESTAIRPORTNAME",
    
    -- Standardized times
    st."DEPTIME_STD" AS "DEPTIME",
    st."ARRTIME_STD" AS "ARRTIME",
    st."CRSDEPTIME_STD" AS "CRSDEPTIME",
    st."CRSARRTIME_STD" AS "CRSARRTIME",
    
    -- Delay fields
    TRY_CAST(s."DEPDELAY" AS INTEGER) AS "DEPDELAY",
    TRY_CAST(s."ARRDELAY" AS INTEGER) AS "ARRDELAY",
    
    -- Standardized booleans
    sb."CANCELLED_STD" AS "CANCELLED",
    sb."DIVERTED_STD" AS "DIVERTED",
    
    -- Standardized distance
    sd."DISTANCE_MILES" AS "DISTANCE",
    
    -- Quality metadata
    hc."HISTORICAL_CONTEXT",
    hc."IS_SENSITIVE_PERIOD",
    qs."OVERALL_QUALITY_SCORE",
    qs."QUALITY_CATEGORY",
    
    -- Data lineage
    s."LOAD_TIMESTAMP",
    CURRENT_TIMESTAMP() AS "CLEAN_TIMESTAMP"

FROM "STAGING_FLIGHTS_RAW" s
LEFT JOIN "VW_STANDARDIZED_BOOLEANS" sb ON s."TRANSACTIONID" = sb."TRANSACTIONID"
LEFT JOIN "VW_CLEANED_TEXT_FIELDS" ct ON s."TRANSACTIONID" = ct."TRANSACTIONID"  
LEFT JOIN "VW_STANDARDIZED_TIMES" st ON s."TRANSACTIONID" = st."TRANSACTIONID"
LEFT JOIN "VW_TAILNUM_QUALITY" tq ON s."TRANSACTIONID" = tq."TRANSACTIONID"
LEFT JOIN "VW_STANDARDIZED_DISTANCE" sd ON s."TRANSACTIONID" = sd."TRANSACTIONID"
LEFT JOIN "VW_HISTORICAL_CONTEXT" hc ON s."TRANSACTIONID" = hc."TRANSACTIONID"
LEFT JOIN "VW_DATA_QUALITY_SCORECARD" qs ON s."TRANSACTIONID" = qs."TRANSACTIONID";

-- ====================
-- 6. DATA QUALITY MONITORING QUERIES
-- ====================

-- Monitor 1: Overall Data Quality Summary
SELECT 
    'Data Quality Summary' AS "REPORT_TYPE",
    COUNT(*) AS "TOTAL_RECORDS",
    SUM(CASE WHEN "QUALITY_CATEGORY" = 'EXCELLENT' THEN 1 ELSE 0 END) AS "EXCELLENT_QUALITY",
    SUM(CASE WHEN "QUALITY_CATEGORY" = 'GOOD' THEN 1 ELSE 0 END) AS "GOOD_QUALITY", 
    SUM(CASE WHEN "QUALITY_CATEGORY" = 'FAIR' THEN 1 ELSE 0 END) AS "FAIR_QUALITY",
    SUM(CASE WHEN "QUALITY_CATEGORY" = 'POOR' THEN 1 ELSE 0 END) AS "POOR_QUALITY",
    ROUND(AVG("OVERALL_QUALITY_SCORE"), 3) AS "AVERAGE_QUALITY_SCORE"
FROM "STAGING_FLIGHTS_CLEANED";

-- Monitor 2: Specific Issue Counts
SELECT 
    'Boolean Issues' AS "ISSUE_TYPE", 
    COUNT(*) AS "AFFECTED_RECORDS"
FROM "STAGING_FLIGHTS_RAW" 
WHERE "CANCELLED" NOT IN ('1', '0', 'True', 'False', 'T', 'F', 'Y', 'N')

UNION ALL

SELECT 
    'Text Contamination',
    COUNT(*)
FROM "STAGING_FLIGHTS_RAW"
WHERE "AIRLINENAME" LIKE '%:%' OR "ORIGAIRPORTNAME" LIKE '%:%'

UNION ALL

SELECT 
    'Time Format Issues',
    COUNT(*)
FROM "STAGING_FLIGHTS_RAW"
WHERE "DEPTIME" IS NULL AND "CANCELLED" NOT IN ('1', 'True', 'T', 'Y')

UNION ALL

SELECT 
    'Tailnum Quality Issues',
    COUNT(*)
FROM "STAGING_FLIGHTS_RAW"
WHERE "TAILNUM" IS NULL OR "TAILNUM" = 'UNKNOW' OR "TAILNUM" LIKE '-%';

-- Monitor 3: Business Rule Violations
WITH violations AS (
    SELECT 
        cv."TRANSACTIONID",
        cv."CANCELLATION_CONSISTENCY",
        dv."DEPDELAY_VALIDATION",
        dv."ARRDELAY_VALIDATION"
    FROM "VW_CANCELLED_FLIGHT_VALIDATION" cv
    LEFT JOIN "VW_DELAY_VALIDATION" dv ON cv."TRANSACTIONID" = dv."TRANSACTIONID"
    WHERE cv."REQUIRES_REVIEW" = 1 
       OR dv."DEPDELAY_VALIDATION" LIKE 'EXTREMELY%'
       OR dv."ARRDELAY_VALIDATION" LIKE 'EXTREMELY%'
)
SELECT 
    'Business Rule Violations' AS "VALIDATION_TYPE",
    COUNT(*) AS "VIOLATION_COUNT",
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM "STAGING_FLIGHTS_RAW"), 2) AS "VIOLATION_PERCENTAGE"
FROM violations;

-- ====================
-- 7. DATA QUALITY ACTION PLAN
-- ====================

-- Action 1: High Priority Issues (Fix Immediately)
SELECT 
    'HIGH PRIORITY' AS "PRIORITY_LEVEL",
    'Standardize Boolean Values' AS "ACTION_REQUIRED",
    'COMPLETED - Applied standardization logic' AS "STATUS",
    COUNT(*) AS "RECORDS_AFFECTED"
FROM "STAGING_FLIGHTS_RAW"
WHERE "CANCELLED" NOT IN ('1', '0', 'True', 'False')

UNION ALL

SELECT 
    'HIGH PRIORITY',
    'Clean Contaminated Text Fields', 
    'COMPLETED - Removed prefixes/suffixes',
    COUNT(*)
FROM "STAGING_FLIGHTS_RAW"
WHERE "AIRLINENAME" LIKE '%:%'

UNION ALL

-- Action 2: Medium Priority Issues (Business Decision Required)
SELECT 
    'MEDIUM PRIORITY',
    'Tail Number Standardization',
    'FLAGGED - Preserve original, add quality flags',
    COUNT(*)
FROM "STAGING_FLIGHTS_RAW"
WHERE "TAILNUM" NOT REGEXP '^N[0-9A-Z]{1,5}[A-Z]{0,2}$' AND "TAILNUM" IS NOT NULL

UNION ALL

-- Action 3: Low Priority Issues (Monitor)
SELECT 
    'LOW PRIORITY',
    'Historical Period Analysis',
    'FLAGGED - Added sensitive period indicators',
    COUNT(*)
FROM "STAGING_FLIGHTS_RAW"
WHERE TRY_CAST("FLIGHTDATE" AS DATE) BETWEEN '2001-09-11' AND '2001-09-20';

-- ====================
-- 8. BUSINESS RECOMMENDATIONS
-- ====================

/*
BUSINESS RECOMMENDATIONS FOR DATA QUALITY:

1. IMMEDIATE ACTIONS (Implemented):
   - ✅ Standardized boolean values to 1/0 format
   - ✅ Cleaned airline and airport names  
   - ✅ Converted time formats to proper TIME type
   - ✅ Extracted numeric distance values

2. BUSINESS DECISIONS NEEDED:
   - How to handle non-standard tail numbers (preserve vs normalize)
   - Treatment of sensitive historical periods (9/11 context)
   - Threshold definitions for "extremely" delayed flights
   - Policy for missing vs null data handling

3. ONGOING MONITORING:
   - Regular quality score tracking
   - Automated alerts for quality degradation
   - Business rule violation reporting
   - Historical trend analysis

4. DATA GOVERNANCE:
   - Document quality standards
   - Establish data stewardship roles
   - Create data quality SLAs
   - Implement automated quality checks
*/

-- Quality Metrics for Business Users
SELECT 
    'FINAL QUALITY METRICS' AS "REPORT_TYPE",
    COUNT(*) AS "TOTAL_FLIGHTS_PROCESSED",
    SUM(CASE WHEN "OVERALL_QUALITY_SCORE" >= 0.8 THEN 1 ELSE 0 END) AS "HIGH_QUALITY_RECORDS",
    SUM(CASE WHEN "IS_SENSITIVE_PERIOD" = 1 THEN 1 ELSE 0 END) AS "SENSITIVE_PERIOD_RECORDS",
    COUNT(DISTINCT "AIRLINECODE") AS "AIRLINES_REPRESENTED",
    COUNT(DISTINCT "ORIGINAIRPORTCODE") AS "AIRPORTS_REPRESENTED",
    MIN("FLIGHT_DATE") AS "DATE_RANGE_START",
    MAX("FLIGHT_DATE") AS "DATE_RANGE_END"
FROM "STAGING_FLIGHTS_CLEANED";
