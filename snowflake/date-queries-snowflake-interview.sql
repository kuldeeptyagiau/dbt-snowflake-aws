-- =====================================================================
-- SNOWFLAKE DATE QUERIES FOR DATA ENGINEERING INTERVIEWS
-- Comprehensive collection of Snowflake-specific date operations and edge cases
-- =====================================================================

-- =====================================================================
-- 1. SNOWFLAKE DATE BASICS
-- =====================================================================

-- Current date and time operations (Snowflake specific)
SELECT 
    CURRENT_TIMESTAMP() as current_timestamp_func,
    CURRENT_TIMESTAMP as current_timestamp_literal,
    CURRENT_DATE() as current_date_func,
    CURRENT_DATE as current_date_literal,
    CURRENT_TIME() as current_time_func,
    CURRENT_TIME as current_time_literal,
    GETDATE() as getdate_alias,  -- Alias for CURRENT_TIMESTAMP
    SYSDATE() as sysdate_func,
    LOCALTIMESTAMP() as local_timestamp,
    SYSTIMESTAMP() as sys_timestamp;

-- Snowflake date formatting
SELECT 
    CURRENT_DATE as original_date,
    TO_VARCHAR(CURRENT_DATE, 'YYYY-MM-DD') as iso_format,
    TO_VARCHAR(CURRENT_DATE, 'DD/MM/YYYY') as uk_format,
    TO_VARCHAR(CURRENT_DATE, 'MM/DD/YYYY') as us_format,
    TO_VARCHAR(CURRENT_DATE, 'MMMM DD, YYYY') as long_format,
    TO_VARCHAR(CURRENT_DATE, 'DAY, MONTH DD, YYYY') as full_format,
    TO_VARCHAR(CURRENT_DATE, 'DY MON DD YYYY') as abbreviated_format;

-- =====================================================================
-- 2. SNOWFLAKE DATE ARITHMETIC
-- =====================================================================

-- DATEADD variations (Snowflake syntax)
WITH date_calculations AS (
    SELECT CURRENT_TIMESTAMP as base_timestamp
)
SELECT 
    base_timestamp,
    DATEADD(YEAR, 1, base_timestamp) as add_1_year,
    DATEADD(QUARTER, -2, base_timestamp) as subtract_2_quarters,
    DATEADD(MONTH, 6, base_timestamp) as add_6_months,
    DATEADD(WEEK, -4, base_timestamp) as subtract_4_weeks,
    DATEADD(DAY, 30, base_timestamp) as add_30_days,
    DATEADD(HOUR, -12, base_timestamp) as subtract_12_hours,
    DATEADD(MINUTE, 45, base_timestamp) as add_45_minutes,
    DATEADD(SECOND, -30, base_timestamp) as subtract_30_seconds,
    DATEADD(MILLISECOND, 500, base_timestamp) as add_500_milliseconds,
    DATEADD(MICROSECOND, 1000, base_timestamp) as add_1000_microseconds,
    DATEADD(NANOSECOND, 500000, base_timestamp) as add_500000_nanoseconds
FROM date_calculations;

-- DATEDIFF variations (Snowflake syntax)
WITH date_ranges AS (
    SELECT 
        '2023-01-01'::DATE as start_date,
        '2023-12-31'::DATE as end_date,
        '2023-01-01 10:30:45'::TIMESTAMP as start_timestamp,
        '2023-12-31 15:20:10'::TIMESTAMP as end_timestamp
)
SELECT 
    start_date,
    end_date,
    DATEDIFF('day', start_date, end_date) as days_between,
    DATEDIFF('week', start_date, end_date) as weeks_between,
    DATEDIFF('month', start_date, end_date) as months_between,
    DATEDIFF('quarter', start_date, end_date) as quarters_between,
    DATEDIFF('year', start_date, end_date) as years_between,
    DATEDIFF('hour', start_timestamp, end_timestamp) as hours_between,
    DATEDIFF('minute', start_timestamp, end_timestamp) as minutes_between,
    DATEDIFF('second', start_timestamp, end_timestamp) as seconds_between
FROM date_ranges;

-- =====================================================================
-- 3. SNOWFLAKE DATE PARTS AND EXTRACTION
-- =====================================================================

-- DATE_PART and EXTRACT functions
WITH sample_timestamps AS (
    SELECT 
        '2023-03-15 14:30:45.123456'::TIMESTAMP as sample_ts,
        '2023-12-31 23:59:59.999999'::TIMESTAMP as year_end_ts
)
SELECT 
    sample_ts,
    -- Using DATE_PART function
    DATE_PART('year', sample_ts) as year_part,
    DATE_PART('month', sample_ts) as month_part,
    DATE_PART('day', sample_ts) as day_part,
    DATE_PART('hour', sample_ts) as hour_part,
    DATE_PART('minute', sample_ts) as minute_part,
    DATE_PART('second', sample_ts) as second_part,
    DATE_PART('millisecond', sample_ts) as millisecond_part,
    DATE_PART('microsecond', sample_ts) as microsecond_part,
    DATE_PART('nanosecond', sample_ts) as nanosecond_part,
    DATE_PART('quarter', sample_ts) as quarter_part,
    DATE_PART('dayofweek', sample_ts) as dayofweek_part,
    DATE_PART('dayofyear', sample_ts) as dayofyear_part,
    DATE_PART('week', sample_ts) as week_part,
    DATE_PART('weekiso', sample_ts) as iso_week_part,
    -- Using EXTRACT function (alternative syntax)
    EXTRACT('year' FROM sample_ts) as extracted_year,
    EXTRACT('month' FROM sample_ts) as extracted_month
FROM sample_timestamps;

-- Day name and month name functions
WITH sample_dates AS (
    SELECT 
        '2023-03-15'::DATE as sample_date,
        '2023-12-25'::DATE as christmas
)
SELECT 
    sample_date,
    DAYNAME(sample_date) as day_name,
    MONTHNAME(sample_date) as month_name,
    TO_VARCHAR(sample_date, 'DAY') as day_name_formatted,
    TO_VARCHAR(sample_date, 'MONTH') as month_name_formatted,
    DAYOFWEEK(sample_date) as day_of_week_number,
    DAYOFYEAR(sample_date) as day_of_year_number
FROM sample_dates;

-- =====================================================================
-- 4. SNOWFLAKE DATE EDGE CASES
-- =====================================================================

-- Time zone conversions (Snowflake specific)
WITH timezone_examples AS (
    SELECT '2023-07-15 14:30:00'::TIMESTAMP as base_timestamp
)
SELECT 
    base_timestamp,
    CONVERT_TIMEZONE('America/New_York', base_timestamp) as ny_time,
    CONVERT_TIMEZONE('Europe/London', base_timestamp) as london_time,
    CONVERT_TIMEZONE('Asia/Tokyo', base_timestamp) as tokyo_time,
    CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', base_timestamp) as utc_to_la,
    CONVERT_TIMEZONE('America/New_York', 'Europe/Paris', base_timestamp) as ny_to_paris
FROM timezone_examples;

-- Leap year and month-end handling
WITH leap_year_scenarios AS (
    SELECT year_value
    FROM VALUES (2020), (2021), (2022), (2023), (2024), (1900), (2000) as years(year_value)
)
SELECT 
    year_value,
    -- Check if leap year
    CASE 
        WHEN (year_value % 4 = 0 AND year_value % 100 != 0) OR (year_value % 400 = 0)
        THEN 'Leap Year'
        ELSE 'Not Leap Year'
    END as leap_year_status,
    -- Try to create Feb 29
    TRY_TO_DATE(year_value || '-02-29', 'YYYY-MM-DD') as feb_29_attempt,
    -- Last day of February
    LAST_DAY(DATE_FROM_PARTS(year_value, 2, 1)) as last_day_of_feb,
    -- Days in February
    DAY(LAST_DAY(DATE_FROM_PARTS(year_value, 2, 1))) as days_in_february
FROM leap_year_scenarios
ORDER BY year_value;

-- Date validation with TRY functions
WITH date_validation_tests AS (
    SELECT test_value, test_description
    FROM VALUES 
        ('2023-02-29', 'Invalid - Feb 29 in non-leap year'),
        ('2024-02-29', 'Valid - Feb 29 in leap year'),
        ('2023-13-01', 'Invalid month'),
        ('2023-12-32', 'Invalid day'),
        ('2023-04-31', 'Invalid day for April'),
        ('2023-12-31', 'Valid date'),
        ('invalid_date', 'Non-date string'),
        ('2023/12/31', 'Different format'),
        (NULL, 'NULL value')
    as tests(test_value, test_description)
)
SELECT 
    test_value,
    test_description,
    TRY_TO_DATE(test_value, 'YYYY-MM-DD') as try_to_date_result,
    TRY_TO_TIMESTAMP(test_value, 'YYYY-MM-DD') as try_to_timestamp_result,
    CASE 
        WHEN TRY_TO_DATE(test_value, 'YYYY-MM-DD') IS NOT NULL 
        THEN 'Valid'
        ELSE 'Invalid'
    END as validation_status
FROM date_validation_tests;

-- =====================================================================
-- 5. SNOWFLAKE BUSINESS DATE FUNCTIONS
-- =====================================================================

-- LAST_DAY function for month/quarter/year ends
WITH business_dates AS (
    SELECT '2023-07-15'::DATE as sample_date
)
SELECT 
    sample_date,
    LAST_DAY(sample_date) as last_day_of_month,
    LAST_DAY(sample_date, 'quarter') as last_day_of_quarter,
    LAST_DAY(sample_date, 'year') as last_day_of_year,
    LAST_DAY(sample_date, 'week') as last_day_of_week,
    -- First day calculations
    DATE_TRUNC('month', sample_date) as first_day_of_month,
    DATE_TRUNC('quarter', sample_date) as first_day_of_quarter,
    DATE_TRUNC('year', sample_date) as first_day_of_year,
    DATE_TRUNC('week', sample_date) as first_day_of_week
FROM business_dates;

-- NEXT_DAY function
WITH next_day_examples AS (
    SELECT '2023-07-15'::DATE as base_date  -- This is a Saturday
)
SELECT 
    base_date,
    DAYNAME(base_date) as base_day_name,
    NEXT_DAY(base_date, 'MONDAY') as next_monday,
    NEXT_DAY(base_date, 'FRIDAY') as next_friday,
    NEXT_DAY(base_date, 'SUNDAY') as next_sunday,
    PREVIOUS_DAY(base_date, 'MONDAY') as previous_monday,
    PREVIOUS_DAY(base_date, 'FRIDAY') as previous_friday
FROM next_day_examples;

-- =====================================================================
-- 6. ADVANCED SNOWFLAKE DATE SCENARIOS
-- =====================================================================

-- Generate date series using TABLE(GENERATOR())
-- This is very useful for creating date dimensions
WITH date_series AS (
    SELECT 
        DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2023-01-01'::DATE) as generated_date
    FROM TABLE(GENERATOR(ROWCOUNT => 365))  -- Generate 365 days for 2023
)
SELECT 
    generated_date,
    DAYNAME(generated_date) as day_name,
    MONTHNAME(generated_date) as month_name,
    DATE_PART('quarter', generated_date) as quarter,
    CASE 
        WHEN DAYOFWEEK(generated_date) IN (0, 6) THEN 'Weekend'  -- Sunday=0, Saturday=6
        ELSE 'Weekday'
    END as day_type,
    -- Business day calculation
    CASE 
        WHEN DAYOFWEEK(generated_date) BETWEEN 1 AND 5 THEN 1  -- Monday=1 to Friday=5
        ELSE 0
    END as is_business_day
FROM date_series
WHERE generated_date <= '2023-12-31'
LIMIT 20;  -- Show first 20 days for demonstration

-- Sliding window date calculations
WITH sales_data AS (
    SELECT date_col, amount
    FROM VALUES 
        ('2023-01-01'::DATE, 100),
        ('2023-01-02'::DATE, 150),
        ('2023-01-03'::DATE, 200),
        ('2023-01-04'::DATE, 120),
        ('2023-01-05'::DATE, 180),
        ('2023-01-08'::DATE, 220),  -- Weekend gap
        ('2023-01-09'::DATE, 160),
        ('2023-01-10'::DATE, 190)
    as sales(date_col, amount)
)
SELECT 
    date_col,
    amount,
    -- Rolling averages
    AVG(amount) OVER (ORDER BY date_col ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as rolling_3day_avg,
    AVG(amount) OVER (ORDER BY date_col ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_7day_avg,
    -- Rolling sums
    SUM(amount) OVER (ORDER BY date_col ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as rolling_3day_sum,
    -- Date-based windows
    AVG(amount) OVER (ORDER BY date_col RANGE BETWEEN INTERVAL '2 days' PRECEDING AND CURRENT ROW) as date_range_avg,
    -- Gap analysis
    LAG(date_col) OVER (ORDER BY date_col) as prev_date,
    DATEDIFF('day', LAG(date_col) OVER (ORDER BY date_col), date_col) as days_gap
FROM sales_data
ORDER BY date_col;

-- =====================================================================
-- 7. SNOWFLAKE DATE FORMAT PARSING
-- =====================================================================

-- Various date format parsing scenarios
WITH date_formats AS (
    SELECT format_example, format_mask, description
    FROM VALUES 
        ('2023-12-31', 'YYYY-MM-DD', 'ISO format'),
        ('12/31/2023', 'MM/DD/YYYY', 'US format'),
        ('31/12/2023', 'DD/MM/YYYY', 'UK format'),
        ('31-Dec-2023', 'DD-MON-YYYY', 'Day-Month-Year with month name'),
        ('2023-12-31 14:30:45', 'YYYY-MM-DD HH24:MI:SS', 'ISO with time'),
        ('Dec 31, 2023', 'MON DD, YYYY', 'US long format'),
        ('2023-365', 'YYYY-DDD', 'Year and day of year'),
        ('2023-W52-7', 'IYYY-IW-ID', 'ISO week format')
    as formats(format_example, format_mask, description)
)
SELECT 
    format_example,
    format_mask,
    description,
    TRY_TO_DATE(format_example, format_mask) as parsed_date,
    CASE 
        WHEN TRY_TO_DATE(format_example, format_mask) IS NOT NULL 
        THEN 'Successfully parsed'
        ELSE 'Failed to parse'
    END as parse_status
FROM date_formats;

-- =====================================================================
-- 8. SNOWFLAKE INTERVIEW SPECIFIC SCENARIOS
-- =====================================================================

-- Question: Calculate customer retention cohorts
WITH user_activity AS (
    SELECT user_id, activity_date
    FROM VALUES 
        (1, '2023-01-15'::DATE),
        (1, '2023-02-20'::DATE),
        (1, '2023-03-10'::DATE),
        (1, '2023-05-05'::DATE),
        (2, '2023-01-10'::DATE),
        (2, '2023-02-15'::DATE),
        (2, '2023-04-20'::DATE),
        (3, '2023-02-05'::DATE),
        (3, '2023-03-25'::DATE),
        (4, '2023-01-20'::DATE),
        (5, '2023-03-01'::DATE),
        (5, '2023-04-15'::DATE)
    as activity(user_id, activity_date)
),
user_cohorts AS (
    SELECT 
        user_id,
        MIN(activity_date) as cohort_month,
        activity_date
    FROM user_activity
    GROUP BY user_id, activity_date
),
cohort_analysis AS (
    SELECT 
        DATE_TRUNC('month', cohort_month) as cohort,
        user_id,
        DATEDIFF('month', cohort_month, activity_date) as months_since_first_activity
    FROM user_cohorts
)
SELECT 
    cohort,
    months_since_first_activity,
    COUNT(DISTINCT user_id) as users_active,
    COUNT(DISTINCT user_id) * 100.0 / 
        FIRST_VALUE(COUNT(DISTINCT user_id)) OVER (
            PARTITION BY cohort 
            ORDER BY months_since_first_activity
        ) as retention_percentage
FROM cohort_analysis
GROUP BY cohort, months_since_first_activity
ORDER BY cohort, months_since_first_activity;

-- Question: Find date ranges with no data (gaps in time series)
WITH expected_dates AS (
    SELECT 
        DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2023-01-01'::DATE) as expected_date
    FROM TABLE(GENERATOR(ROWCOUNT => 31))  -- January 2023
),
actual_data AS (
    SELECT activity_date
    FROM VALUES 
        ('2023-01-01'::DATE),
        ('2023-01-02'::DATE),
        ('2023-01-03'::DATE),
        ('2023-01-06'::DATE),  -- Gap: 01-04, 01-05 missing
        ('2023-01-07'::DATE),
        ('2023-01-10'::DATE),  -- Gap: 01-08, 01-09 missing
        ('2023-01-15'::DATE)   -- Gap: 01-11 to 01-14 missing
    as data(activity_date)
)
SELECT 
    e.expected_date,
    CASE 
        WHEN a.activity_date IS NULL THEN 'Missing Data'
        ELSE 'Data Available'
    END as data_status
FROM expected_dates e
LEFT JOIN actual_data a ON e.expected_date = a.activity_date
WHERE e.expected_date <= '2023-01-31'
ORDER BY e.expected_date;

-- Question: Calculate business metrics with date aggregations
WITH daily_metrics AS (
    SELECT metric_date, revenue, users
    FROM VALUES 
        ('2023-01-01'::DATE, 1000, 50),
        ('2023-01-02'::DATE, 1200, 60),
        ('2023-01-03'::DATE, 800, 45),
        ('2023-01-04'::DATE, 1500, 75),
        ('2023-01-05'::DATE, 1100, 55),
        ('2023-01-08'::DATE, 1300, 65),
        ('2023-01-09'::DATE, 900, 48),
        ('2023-01-10'::DATE, 1400, 70)
    as metrics(metric_date, revenue, users)
)
SELECT 
    metric_date,
    revenue,
    users,
    -- Daily calculations
    revenue / users as revenue_per_user,
    -- Weekly aggregations
    DATE_TRUNC('week', metric_date) as week_start,
    SUM(revenue) OVER (
        PARTITION BY DATE_TRUNC('week', metric_date)
    ) as weekly_revenue,
    AVG(users) OVER (
        PARTITION BY DATE_TRUNC('week', metric_date)
    ) as weekly_avg_users,
    -- Running totals
    SUM(revenue) OVER (ORDER BY metric_date) as running_revenue_total,
    -- Month-to-date calculations
    SUM(revenue) OVER (
        PARTITION BY DATE_TRUNC('month', metric_date)
        ORDER BY metric_date
    ) as mtd_revenue
FROM daily_metrics
ORDER BY metric_date;

-- =====================================================================
-- 9. SNOWFLAKE DATE PERFORMANCE TIPS
-- =====================================================================

-- Demonstrate efficient date filtering (SARGable predicates)
SELECT 'Snowflake Performance Examples' as note;

-- GOOD: These are SARGable and will use indexes efficiently
/*
WHERE date_column >= '2023-01-01'::DATE 
  AND date_column < '2024-01-01'::DATE

WHERE date_column >= DATEADD('day', -30, CURRENT_DATE())

WHERE date_column BETWEEN '2023-01-01' AND '2023-12-31'
*/

-- BAD: These prevent index usage
/*
WHERE YEAR(date_column) = 2023
WHERE DATE_PART('month', date_column) = 12  
WHERE DATEDIFF('day', date_column, CURRENT_DATE()) <= 30
*/

-- Clustering keys for large date-partitioned tables
SELECT 'Consider clustering on date columns for large tables' as clustering_tip;
