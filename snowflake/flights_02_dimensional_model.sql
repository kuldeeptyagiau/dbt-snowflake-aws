-- Flights Case Study - Phase 2: Dimensional Model Creation
-- =========================================================

-- Prerequisite: Run flights_01_data_exploration.sql first
-- Assumes STAGING_FLIGHTS_RAW table exists with data

USE SCHEMA "candidate_1234";  -- Replace with your candidate number

-- =======================
-- DIMENSION TABLES
-- =======================

-- Step 1: Create DIM_AIRLINE
-- ---------------------------
CREATE OR REPLACE TABLE "DIM_AIRLINE" (
    "AIRLINE_KEY" NUMBER AUTOINCREMENT,
    "AIRLINE_CODE" VARCHAR(10),
    "AIRLINENAME" VARCHAR(255),
    "AIRLINENAME_CLEAN" VARCHAR(255),
    PRIMARY KEY ("AIRLINE_KEY")
);

-- Load airline dimension with cleaned names
INSERT INTO "DIM_AIRLINE" ("AIRLINE_CODE", "AIRLINENAME", "AIRLINENAME_CLEAN")
SELECT DISTINCT 
    "AIRLINE",
    "AIRLINENAME",
    -- Remove airline codes in parentheses from airline names
    TRIM(REGEXP_REPLACE("AIRLINENAME", '\\s*\\([^)]*\\)\\s*', '')) as cleaned_name
FROM STAGING_FLIGHTS_RAW
WHERE "AIRLINE" IS NOT NULL 
  AND TRIM("AIRLINE") != ''
ORDER BY "AIRLINE";

-- Verify airline dimension
SELECT * FROM "DIM_AIRLINE" ORDER BY "AIRLINE_CODE";

-- Step 2: Create DIM_AIRPORT 
-- ---------------------------
CREATE OR REPLACE TABLE "DIM_AIRPORT" (
    "AIRPORT_KEY" NUMBER AUTOINCREMENT,
    "AIRPORT_CODE" VARCHAR(10),
    "AIRPORT_NAME" VARCHAR(255),
    "AIRPORT_NAME_CLEAN" VARCHAR(255),
    "AIRPORT_TYPE" VARCHAR(20), -- 'ORIGIN' or 'DESTINATION' or 'BOTH'
    PRIMARY KEY ("AIRPORT_KEY")
);

-- Create a unified airport list from both origin and destination
WITH all_airports AS (
    -- Origin airports
    SELECT DISTINCT 
        "ORIGAIRPORT" as airport_code,
        "ORIGAIRPORTNAME" as airport_name,
        'ORIGIN' as airport_type
    FROM STAGING_FLIGHTS_RAW
    WHERE "ORIGAIRPORT" IS NOT NULL AND TRIM("ORIGAIRPORT") != ''
    
    UNION
    
    -- Destination airports  
    SELECT DISTINCT
        "DESTAIRPORT" as airport_code,
        "DESTAIRPORTNAME" as airport_name,
        'DESTINATION' as airport_type
    FROM STAGING_FLIGHTS_RAW
    WHERE "DESTAIRPORT" IS NOT NULL AND TRIM("DESTAIRPORT") != ''
),
consolidated_airports AS (
    SELECT 
        airport_code,
        airport_name,
        CASE 
            WHEN COUNT(DISTINCT airport_type) > 1 THEN 'BOTH'
            ELSE MAX(airport_type)
        END as airport_type
    FROM all_airports
    GROUP BY airport_code, airport_name
)

INSERT INTO "DIM_AIRPORT" ("AIRPORT_CODE", "AIRPORT_NAME", "AIRPORT_NAME_CLEAN", "AIRPORT_TYPE")
SELECT 
    airport_code,
    airport_name,
    -- Remove city and state from airport names (assumes format: "Airport Name, City, ST")
    TRIM(REGEXP_REPLACE(airport_name, ',\\s*[^,]+,\\s*[A-Z]{2}\\s*$', '')) as cleaned_name,
    airport_type
FROM consolidated_airports
ORDER BY airport_code;

-- Verify airport dimension
SELECT * FROM "DIM_AIRPORT" ORDER BY "AIRPORT_CODE" LIMIT 20;

-- Step 3: Create DIM_DATE (Optional but Recommended)
-- ---------------------------------------------------
CREATE OR REPLACE TABLE "DIM_DATE" (
    "DATE_KEY" NUMBER AUTOINCREMENT,
    "FLIGHT_DATE" DATE,
    "YEAR" NUMBER(4,0),
    "MONTH" NUMBER(2,0),
    "DAY" NUMBER(2,0),
    "MONTH_NAME" VARCHAR(20),
    "DAY_OF_WEEK" NUMBER(1,0),
    "DAY_NAME" VARCHAR(20),
    "QUARTER" NUMBER(1,0),
    "IS_WEEKEND" BOOLEAN,
    PRIMARY KEY ("DATE_KEY")
);

-- Load date dimension from flight dates in the data
INSERT INTO "DIM_DATE" (
    "FLIGHT_DATE", "YEAR", "MONTH", "DAY", "MONTH_NAME", 
    "DAY_OF_WEEK", "DAY_NAME", "QUARTER", "IS_WEEKEND"
)
WITH unique_dates AS (
    SELECT DISTINCT TRY_CAST("FLIGHTDATE" AS DATE) as flight_date
    FROM STAGING_FLIGHTS_RAW
    WHERE TRY_CAST("FLIGHTDATE" AS DATE) IS NOT NULL
)
SELECT 
    flight_date,
    YEAR(flight_date) as year,
    MONTH(flight_date) as month,
    DAY(flight_date) as day,
    MONTHNAME(flight_date) as month_name,
    DAYOFWEEK(flight_date) as day_of_week,
    DAYNAME(flight_date) as day_name,
    QUARTER(flight_date) as quarter,
    CASE WHEN DAYOFWEEK(flight_date) IN (1, 7) THEN TRUE ELSE FALSE END as is_weekend
FROM unique_dates
WHERE flight_date IS NOT NULL
ORDER BY flight_date;

-- Verify date dimension
SELECT * FROM "DIM_DATE" ORDER BY "FLIGHT_DATE" LIMIT 10;

-- =======================
-- FACT TABLE
-- =======================

-- Step 4: Create FACT_FLIGHTS
-- ----------------------------
CREATE OR REPLACE TABLE "FACT_FLIGHTS" (
    "TRANSACTIONID" VARCHAR(255),
    "AIRLINE_KEY" NUMBER,
    "ORIGIN_AIRPORT_KEY" NUMBER,
    "DEST_AIRPORT_KEY" NUMBER,
    "DATE_KEY" NUMBER,
    
    -- Original measures
    "DISTANCE" NUMBER(10,2),
    "CANCELLED" NUMBER(1,0),
    "DEPTIME" TIME,
    "ARRTIME" TIME,
    "DEPDELAY" NUMBER(10,2),
    "ARRDELAY" NUMBER(10,2),
    "FLIGHTDATE" DATE,
    "TAILNUM" VARCHAR(20),
    
    -- Calculated measures (as per requirements)
    "DISTANCEGROUP" VARCHAR(30),
    "DEPDELAYGT15" NUMBER(1,0),
    "NEXTDAYARR" NUMBER(1,0),
    
    -- Foreign key constraints
    FOREIGN KEY ("AIRLINE_KEY") REFERENCES "DIM_AIRLINE"("AIRLINE_KEY"),
    FOREIGN KEY ("ORIGIN_AIRPORT_KEY") REFERENCES "DIM_AIRPORT"("AIRPORT_KEY"),
    FOREIGN KEY ("DEST_AIRPORT_KEY") REFERENCES "DIM_AIRPORT"("AIRPORT_KEY"),
    FOREIGN KEY ("DATE_KEY") REFERENCES "DIM_DATE"("DATE_KEY")
);

-- Step 5: Load FACT_FLIGHTS with business logic
-- ----------------------------------------------
INSERT INTO "FACT_FLIGHTS" (
    "TRANSACTIONID", "AIRLINE_KEY", "ORIGIN_AIRPORT_KEY", "DEST_AIRPORT_KEY", "DATE_KEY",
    "DISTANCE", "CANCELLED", "DEPTIME", "ARRTIME", "DEPDELAY", "ARRDELAY", 
    "FLIGHTDATE", "TAILNUM", "DISTANCEGROUP", "DEPDELAYGT15", "NEXTDAYARR"
)
SELECT 
    s."TRANSACTIONID",
    a."AIRLINE_KEY",
    oa."AIRPORT_KEY" as origin_airport_key,
    da."AIRPORT_KEY" as dest_airport_key,
    d."DATE_KEY",
    
    -- Clean and convert measures
    TRY_CAST(s."DISTANCE" AS NUMBER(10,2)) as distance,
    CASE WHEN UPPER(TRIM(s."CANCELLED")) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END as cancelled,
    TRY_CAST(s."DEPTIME" AS TIME) as deptime,
    TRY_CAST(s."ARRTIME" AS TIME) as arrtime,
    TRY_CAST(s."DEPDELAY" AS NUMBER(10,2)) as depdelay,
    TRY_CAST(s."ARRDELAY" AS NUMBER(10,2)) as arrdelay,
    TRY_CAST(s."FLIGHTDATE" AS DATE) as flightdate,
    s."TAILNUM",
    
    -- DISTANCEGROUP calculation (as per requirements: 0-100, 201-300, etc.)
    CASE 
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) IS NULL THEN 'Unknown'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 100 THEN '0-100 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 200 THEN '101-200 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 300 THEN '201-300 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 400 THEN '301-400 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 500 THEN '401-500 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 600 THEN '501-600 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 700 THEN '601-700 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 800 THEN '701-800 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 900 THEN '801-900 miles'
        WHEN TRY_CAST(s."DISTANCE" AS NUMBER) <= 1000 THEN '901-1000 miles'
        ELSE CAST(FLOOR(TRY_CAST(s."DISTANCE" AS NUMBER)/100)*100+1 AS VARCHAR) || '-' || 
             CAST((FLOOR(TRY_CAST(s."DISTANCE" AS NUMBER)/100)+1)*100 AS VARCHAR) || ' miles'
    END as distancegroup,
    
    -- DEPDELAYGT15 calculation
    CASE 
        WHEN TRY_CAST(s."DEPDELAY" AS NUMBER) > 15 THEN 1 
        ELSE 0 
    END as depdelaygt15,
    
    -- NEXTDAYARR calculation (arrival time is next day if arrival < departure)
    CASE 
        WHEN TRY_CAST(s."ARRTIME" AS TIME) < TRY_CAST(s."DEPTIME" AS TIME) THEN 1
        ELSE 0 
    END as nextdayarr

FROM STAGING_FLIGHTS_RAW s
    LEFT JOIN "DIM_AIRLINE" a ON s."AIRLINE" = a."AIRLINE_CODE"
    LEFT JOIN "DIM_AIRPORT" oa ON s."ORIGAIRPORT" = oa."AIRPORT_CODE"
    LEFT JOIN "DIM_AIRPORT" da ON s."DESTAIRPORT" = da."AIRPORT_CODE"  
    LEFT JOIN "DIM_DATE" d ON TRY_CAST(s."FLIGHTDATE" AS DATE) = d."FLIGHT_DATE"
WHERE s."TRANSACTIONID" IS NOT NULL 
  AND TRIM(s."TRANSACTIONID") != '';

-- =======================
-- DATA VALIDATION
-- =======================

-- Step 6: Validate the model
-- ---------------------------

-- Check row counts
SELECT 'STAGING' as table_name, COUNT(*) as row_count FROM STAGING_FLIGHTS_RAW
UNION ALL
SELECT 'FACT_FLIGHTS', COUNT(*) FROM "FACT_FLIGHTS"
UNION ALL
SELECT 'DIM_AIRLINE', COUNT(*) FROM "DIM_AIRLINE"
UNION ALL  
SELECT 'DIM_AIRPORT', COUNT(*) FROM "DIM_AIRPORT"
UNION ALL
SELECT 'DIM_DATE', COUNT(*) FROM "DIM_DATE";

-- Validate DISTANCEGROUP calculations
SELECT 
    "DISTANCEGROUP",
    COUNT(*) as flight_count,
    MIN("DISTANCE") as min_distance,
    MAX("DISTANCE") as max_distance,
    AVG("DISTANCE") as avg_distance
FROM "FACT_FLIGHTS"
WHERE "DISTANCEGROUP" != 'Unknown'
GROUP BY "DISTANCEGROUP"
ORDER BY min_distance;

-- Validate DEPDELAYGT15 calculations
SELECT 
    "DEPDELAYGT15",
    COUNT(*) as flight_count,
    MIN("DEPDELAY") as min_delay,
    MAX("DEPDELAY") as max_delay,
    AVG("DEPDELAY") as avg_delay
FROM "FACT_FLIGHTS"
GROUP BY "DEPDELAYGT15"
ORDER BY "DEPDELAYGT15";

-- Validate NEXTDAYARR calculations
SELECT 
    "NEXTDAYARR",
    COUNT(*) as flight_count,
    COUNT(CASE WHEN "DEPTIME" IS NOT NULL AND "ARRTIME" IS NOT NULL THEN 1 END) as valid_times
FROM "FACT_FLIGHTS"
GROUP BY "NEXTDAYARR"
ORDER BY "NEXTDAYARR";

-- Check for missing dimension keys
SELECT 
    COUNT(*) as total_flights,
    COUNT(*) - COUNT("AIRLINE_KEY") as missing_airline_keys,
    COUNT(*) - COUNT("ORIGIN_AIRPORT_KEY") as missing_origin_keys,
    COUNT(*) - COUNT("DEST_AIRPORT_KEY") as missing_dest_keys,
    COUNT(*) - COUNT("DATE_KEY") as missing_date_keys
FROM "FACT_FLIGHTS";

-- Summary statistics
SELECT 
    'Model Creation Complete' as status,
    (SELECT COUNT(*) FROM "FACT_FLIGHTS") as fact_records,
    (SELECT COUNT(*) FROM "DIM_AIRLINE") as airlines,
    (SELECT COUNT(*) FROM "DIM_AIRPORT") as airports,
    (SELECT COUNT(*) FROM "DIM_DATE") as date_records;
