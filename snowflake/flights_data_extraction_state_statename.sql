**🎯 SOLUTION: POPULATE MISSING STATENAME FROM AIRPORTNAME PREFIX**

Perfect! You've identified a **data recovery opportunity** for 40K records. Here's the complete solution:

## **📋 EXTRACTION & MAPPING STRATEGY:**

### **Step 1: Extract State Code from Airport Name Prefix**
```sql
-- Extract state code (last 2 characters before colon)
RIGHT(SPLIT_PART(ORIGAIRPORTNAME, ':', 1), 2) AS EXTRACTED_STATE_CODE

-- Examples:
-- "CharlestonSC:" → "SC"  
-- "AtlantaGA:" → "GA"
-- "Dallas/Fort WorthTX:" → "TX"
```

### **Step 2: Create State Code to State Name Mapping**
```sql
-- COMPLETE STATE MAPPING TABLE
CREATE OR REPLACE TABLE STATE_CODE_LOOKUP AS
SELECT * FROM VALUES
    ('AL', 'Alabama'), ('AK', 'Alaska'), ('AZ', 'Arizona'), ('AR', 'Arkansas'), 
    ('CA', 'California'), ('CO', 'Colorado'), ('CT', 'Connecticut'), ('DE', 'Delaware'), 
    ('FL', 'Florida'), ('GA', 'Georgia'), ('HI', 'Hawaii'), ('ID', 'Idaho'), 
    ('IL', 'Illinois'), ('IN', 'Indiana'), ('IA', 'Iowa'), ('KS', 'Kansas'), 
    ('KY', 'Kentucky'), ('LA', 'Louisiana'), ('ME', 'Maine'), ('MD', 'Maryland'), 
    ('MA', 'Massachusetts'), ('MI', 'Michigan'), ('MN', 'Minnesota'), ('MS', 'Mississippi'), 
    ('MO', 'Missouri'), ('MT', 'Montana'), ('NE', 'Nebraska'), ('NV', 'Nevada'), 
    ('NH', 'New Hampshire'), ('NJ', 'New Jersey'), ('NM', 'New Mexico'), ('NY', 'New York'), 
    ('NC', 'North Carolina'), ('ND', 'North Dakota'), ('OH', 'Ohio'), ('OK', 'Oklahoma'), 
    ('OR', 'Oregon'), ('PA', 'Pennsylvania'), ('RI', 'Rhode Island'), ('SC', 'South Carolina'), 
    ('SD', 'South Dakota'), ('TN', 'Tennessee'), ('TX', 'Texas'), ('UT', 'Utah'), 
    ('VT', 'Vermont'), ('VA', 'Virginia'), ('WA', 'Washington'), ('WV', 'West Virginia'), 
    ('WI', 'Wisconsin'), ('WY', 'Wyoming'), ('DC', 'District of Columbia')
AS t(STATE_CODE, STATE_NAME);
```

### **Step 3: Populate Missing State & StateName**
```sql
-- POPULATE 40K MISSING RECORDS
UPDATE STAGING_FLIGHTS_RAW 
SET 
    -- Populate missing ORIGIN state data
    ORIGINSTATE = CASE 
        WHEN ORIGINSTATE IS NULL AND ORIGAIRPORTNAME REGEXP '.*[A-Z]{2}:'
        THEN RIGHT(SPLIT_PART(ORIGAIRPORTNAME, ':', 1), 2)
        ELSE ORIGINSTATE 
    END,
    
    ORIGINSTATENAME = CASE 
        WHEN ORIGINSTATENAME IS NULL AND ORIGAIRPORTNAME REGEXP '.*[A-Z]{2}:'
        THEN (SELECT STATE_NAME FROM STATE_CODE_LOOKUP 
              WHERE STATE_CODE = RIGHT(SPLIT_PART(ORIGAIRPORTNAME, ':', 1), 2))
        ELSE ORIGINSTATENAME
    END,
    
    -- Populate missing DESTINATION state data
    DESTSTATE = CASE 
        WHEN DESTSTATE IS NULL AND DESTAIRPORTNAME REGEXP '.*[A-Z]{2}:'
        THEN RIGHT(SPLIT_PART(DESTAIRPORTNAME, ':', 1), 2)
        ELSE DESTSTATE
    END,
    
    DESTSTATENAME = CASE 
        WHEN DESTSTATENAME IS NULL AND DESTAIRPORTNAME REGEXP '.*[A-Z]{2}:'
        THEN (SELECT STATE_NAME FROM STATE_CODE_LOOKUP 
              WHERE STATE_CODE = RIGHT(SPLIT_PART(DESTAIRPORTNAME, ':', 1), 2))
        ELSE DESTSTATENAME
    END

WHERE ORIGINSTATE IS NULL OR ORIGINSTATENAME IS NULL 
   OR DESTSTATE IS NULL OR DESTSTATENAME IS NULL;
```

### **Step 4: Validation Query**
```sql
-- VALIDATE SUCCESS OF DATA POPULATION
SELECT 
    'State Data Population Results' AS RESULT_TYPE,
    
    -- Before and after counts
    COUNT(CASE WHEN ORIGINSTATE IS NULL THEN 1 END) AS REMAINING_MISSING_ORIGIN_STATE,
    COUNT(CASE WHEN ORIGINSTATENAME IS NULL THEN 1 END) AS REMAINING_MISSING_ORIGIN_STATENAME,
    COUNT(CASE WHEN DESTSTATE IS NULL THEN 1 END) AS REMAINING_MISSING_DEST_STATE,
    COUNT(CASE WHEN DESTSTATENAME IS NULL THEN 1 END) AS REMAINING_MISSING_DEST_STATENAME,
    
    -- Recovery success rate
    COUNT(CASE WHEN ORIGINSTATE IS NOT NULL AND ORIGINSTATENAME IS NOT NULL 
                AND DESTSTATE IS NOT NULL AND DESTSTATENAME IS NOT NULL 
           THEN 1 END) AS COMPLETE_STATE_DATA_RECORDS,
           
    COUNT(*) AS TOTAL_RECORDS,
    
    ROUND(COUNT(CASE WHEN ORIGINSTATE IS NOT NULL AND ORIGINSTATENAME IS NOT NULL 
                     AND DESTSTATE IS NOT NULL AND DESTSTATENAME IS NOT NULL 
                THEN 1 END) * 100.0 / COUNT(*), 2) AS COMPLETENESS_PERCENTAGE

FROM STAGING_FLIGHTS_RAW;
```

## **🎯 EXPECTED RESULTS:**
- **40K records** will get populated state codes (SC, GA, TX, etc.)
- **40K records** will get populated state names (South Carolina, Georgia, Texas)
- **Data completeness** increases from ~60% to ~95%+
- **Geographic analysis** becomes possible for all flights

This approach **maximizes data recovery** using the embedded information in airport names!