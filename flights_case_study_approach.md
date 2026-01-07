# Flights Case Study - Comprehensive Approach

## Executive Summary
This document outlines a step-by-step approach to complete the Snowflake flights case study, including data exploration, dimensional modeling, ETL processes, and presentation preparation.

## Phase 1: Initial Data Exploration and Setup

### Step 1: Connect to Snowflake and Explore Data
```sql
-- Connect to the recruitment database
USE DATABASE RECRUITMENT_DB;
USE SCHEMA PUBLIC;

-- List files in the stage to confirm data availability
LIST @RECRUITMENT_DB.PUBLIC.S3_FOLDER;

-- Explore the file structure without loading
SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
LIMIT 10;
```

### Step 2: Create Working Schema
```sql
-- Create your candidate schema (replace #### with your candidate number)
CREATE SCHEMA IF NOT EXISTS "candidate_####";
USE SCHEMA "candidate_####";
```

### Step 3: Create Staging Table for Initial Load
```sql
-- Create staging table with VARCHAR columns for initial exploration
CREATE OR REPLACE TABLE STAGING_FLIGHTS (
    RAW_DATA VARIANT
);

-- Alternative: Create staging with all VARCHAR columns
CREATE OR REPLACE TABLE STAGING_FLIGHTS_RAW (
    TRANSACTIONID VARCHAR,
    AIRLINE VARCHAR,
    AIRLINENAME VARCHAR,
    -- Add all other columns as VARCHAR initially
);
```

## Phase 2: Data Profiling and Quality Assessment

### Step 4: Load Raw Data for Analysis
```sql
-- Copy data from stage to staging table
COPY INTO STAGING_FLIGHTS_RAW
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER/flights.gz
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ENCODING = 'UTF8'
);
```

### Step 5: Data Quality Assessment
```sql
-- Check record counts and basic statistics
SELECT COUNT(*) as total_records FROM STAGING_FLIGHTS_RAW;

-- Check for nulls in key columns
SELECT 
    COUNT(*) - COUNT(TRANSACTIONID) as null_transaction_ids,
    COUNT(*) - COUNT(AIRLINE) as null_airlines,
    COUNT(*) - COUNT(DISTANCE) as null_distances
FROM STAGING_FLIGHTS_RAW;

-- Check data ranges and outliers
SELECT 
    MIN(DISTANCE) as min_distance,
    MAX(DISTANCE) as max_distance,
    AVG(DISTANCE) as avg_distance,
    MIN(DEPDELAY) as min_delay,
    MAX(DEPDELAY) as max_delay
FROM STAGING_FLIGHTS_RAW
WHERE TRY_CAST(DISTANCE AS NUMBER) IS NOT NULL;
```

## Phase 3: Dimensional Model Design

### Step 6: Design Dimension Tables

#### DIM_AIRLINE
- Clean airline names (remove codes)
- Deduplicate airlines
- Add surrogate keys

#### DIM_AIRPORT  
- Separate origin and destination airports
- Clean airport names (remove city/state)
- Handle airport codes

#### DIM_DATE (Optional)
- Create date dimension for departure/arrival dates
- Include useful date attributes

### Step 7: Design Fact Table Structure
```sql
-- FACT_FLIGHTS will include:
-- - All measures (delays, distances, times)
-- - Foreign keys to dimensions
-- - Calculated columns (DISTANCEGROUP, DEPDELAYGT15, NEXTDAYARR)
```

## Phase 4: ETL Implementation

### Step 8: Create and Load Dimension Tables

#### Create DIM_AIRLINE
```sql
CREATE OR REPLACE TABLE "DIM_AIRLINE" (
    "AIRLINE_KEY" NUMBER AUTOINCREMENT,
    "AIRLINE_CODE" VARCHAR(10),
    "AIRLINENAME" VARCHAR(255),
    PRIMARY KEY ("AIRLINE_KEY")
);

-- Clean and load airline data
INSERT INTO "DIM_AIRLINE" ("AIRLINE_CODE", "AIRLINENAME")
SELECT DISTINCT 
    "AIRLINE",
    TRIM(REGEXP_REPLACE("AIRLINENAME", '\\([^)]*\\)', '')) as cleaned_name
FROM STAGING_FLIGHTS_RAW
WHERE "AIRLINE" IS NOT NULL;
```

#### Create DIM_AIRPORT
```sql
CREATE OR REPLACE TABLE "DIM_AIRPORT" (
    "AIRPORT_KEY" NUMBER AUTOINCREMENT,
    "AIRPORT_CODE" VARCHAR(10),
    "ORIGAIRPORTNAME" VARCHAR(255),
    PRIMARY KEY ("AIRPORT_KEY")
);

-- Load origin airports
INSERT INTO "DIM_AIRPORT" ("AIRPORT_CODE", "ORIGAIRPORTNAME")
SELECT DISTINCT 
    "ORIGAIRPORT",
    TRIM(REGEXP_REPLACE("ORIGAIRPORTNAME", ', [A-Z]{2}$', '')) as cleaned_name
FROM STAGING_FLIGHTS_RAW
WHERE "ORIGAIRPORT" IS NOT NULL;

-- Load destination airports (if different logic needed)
```

### Step 9: Create and Load Fact Table
```sql
CREATE OR REPLACE TABLE "FACT_FLIGHTS" (
    "TRANSACTIONID" VARCHAR(50),
    "AIRLINE_KEY" NUMBER,
    "ORIGIN_AIRPORT_KEY" NUMBER,
    "DEST_AIRPORT_KEY" NUMBER,
    "DISTANCE" NUMBER(10,2),
    "DISTANCEGROUP" VARCHAR(20),
    "DEPDELAY" NUMBER(10,2),
    "DEPDELAYGT15" NUMBER(1,0),
    "ARRTIME" TIME,
    "DEPTIME" TIME,
    "NEXTDAYARR" NUMBER(1,0),
    "CANCELLED" NUMBER(1,0),
    -- Add other relevant measures
    FOREIGN KEY ("AIRLINE_KEY") REFERENCES "DIM_AIRLINE"("AIRLINE_KEY"),
    FOREIGN KEY ("ORIGIN_AIRPORT_KEY") REFERENCES "DIM_AIRPORT"("AIRPORT_KEY")
);
```

### Step 10: Implement Business Logic for Calculated Fields
```sql
-- DISTANCEGROUP calculation
CASE 
    WHEN distance <= 100 THEN '0-100 miles'
    WHEN distance <= 200 THEN '101-200 miles'
    WHEN distance <= 300 THEN '201-300 miles'
    WHEN distance <= 400 THEN '301-400 miles'
    -- Continue pattern
    ELSE CAST(FLOOR(distance/100)*100+1 AS VARCHAR) || '-' || 
         CAST((FLOOR(distance/100)+1)*100 AS VARCHAR) || ' miles'
END as "DISTANCEGROUP"

-- DEPDELAYGT15 calculation
CASE WHEN TRY_CAST(depdelay AS NUMBER) > 15 THEN 1 ELSE 0 END as "DEPDELAYGT15"

-- NEXTDAYARR calculation (compare arrival vs departure times)
CASE 
    WHEN TRY_CAST(arrtime AS TIME) < TRY_CAST(deptime AS TIME) THEN 1 
    ELSE 0 
END as "NEXTDAYARR"
```

## Phase 5: Create Final View

### Step 11: Create VW_FLIGHTS
```sql
CREATE OR REPLACE VIEW "VW_FLIGHTS" AS
SELECT 
    f."TRANSACTIONID",
    f."DISTANCEGROUP", 
    f."DEPDELAYGT15",
    f."NEXTDAYARR",
    a."AIRLINENAME",
    oa."ORIGAIRPORTNAME",
    da."ORIGAIRPORTNAME" as "DESTAIRPORTNAME",
    f."DISTANCE",
    f."DEPDELAY",
    f."CANCELLED",
    -- Include other relevant columns
FROM "FACT_FLIGHTS" f
LEFT JOIN "DIM_AIRLINE" a ON f."AIRLINE_KEY" = a."AIRLINE_KEY" 
LEFT JOIN "DIM_AIRPORT" oa ON f."ORIGIN_AIRPORT_KEY" = oa."AIRPORT_KEY"
LEFT JOIN "DIM_AIRPORT" da ON f."DEST_AIRPORT_KEY" = da."AIRPORT_KEY";
```

## Phase 6: Data Quality Documentation

### Step 12: Document Data Quality Issues
Create a comprehensive list of data quality issues found:

1. **Missing Values**: Document null patterns and handling strategy
2. **Data Type Issues**: Invalid dates, non-numeric values in numeric fields
3. **Outliers**: Unrealistic flight distances or delays
4. **Inconsistent Formatting**: Airport names with different formats
5. **Business Logic Violations**: Arrival before departure times

### Solutions Implemented:
- Data cleansing rules applied
- Default value strategies
- Error handling approaches

## Phase 7: Testing and Validation

### Step 13: Validate Results
```sql
-- Test row counts match
SELECT 'STAGING' as source, COUNT(*) as cnt FROM STAGING_FLIGHTS_RAW
UNION ALL
SELECT 'FACT', COUNT(*) FROM "FACT_FLIGHTS"
UNION ALL  
SELECT 'VIEW', COUNT(*) FROM "VW_FLIGHTS";

-- Test calculated fields
SELECT 
    "DISTANCEGROUP",
    COUNT(*) as flight_count,
    MIN("DISTANCE") as min_dist,
    MAX("DISTANCE") as max_dist
FROM "VW_FLIGHTS"
GROUP BY "DISTANCEGROUP"
ORDER BY min_dist;
```

## Phase 8: Presentation Preparation

### Key Points for Presentation:
1. **Data Overview**: Size, scope, and business context
2. **Dimensional Model**: Why this design was chosen
3. **Data Quality Issues**: What was found and how it was resolved
4. **Business Value**: How the model supports analytics
5. **Recommendations**: Future improvements or considerations

### Presentation Structure (10-15 minutes):
1. **Introduction** (2 minutes): Problem statement and approach
2. **Data Analysis** (3 minutes): Key findings about the dataset
3. **Solution Design** (4 minutes): Dimensional model explanation
4. **Data Quality** (3 minutes): Issues found and solutions
5. **Business Value** (2 minutes): How this enables analytics
6. **Q&A** (1-2 minutes): Address questions

## Tools and Best Practices

### Recommended Tools:
- Snowflake Web UI for development
- SQL client (SnowSQL, DBeaver) for complex queries
- Documentation tool (Markdown files)
- Presentation software (PowerPoint, Google Slides)

### Best Practices:
- Use consistent naming conventions
- Document all transformations
- Test edge cases thoroughly
- Keep presentation business-focused
- Prepare for technical questions

## Risk Mitigation

### Potential Issues and Solutions:
1. **Large Dataset**: Use sampling for initial exploration
2. **Complex Data Issues**: Document assumptions made
3. **Performance**: Consider partitioning strategies
4. **Time Constraints**: Prioritize core requirements first

This comprehensive approach ensures you address all requirements while demonstrating strong data engineering and communication skills.
