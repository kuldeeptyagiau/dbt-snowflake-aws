-- =====================================================================
-- DATE QUERIES FOR DATA ENGINEERING INTERVIEWS
-- Comprehensive collection of date operations, variations, and edge cases
-- =====================================================================

-- =====================================================================
-- 1. BASIC DATE OPERATIONS
-- =====================================================================

-- Current date and time operations
SELECT 
    GETDATE() as current_datetime,
    GETUTCDATE() as current_utc_datetime,
    CAST(GETDATE() as DATE) as current_date,
    CAST(GETDATE() as TIME) as current_time,
    SYSDATETIME() as system_datetime_high_precision,
    SYSUTCDATETIME() as system_utc_datetime_high_precision;

-- Date formatting and conversion
SELECT 
    GETDATE() as original_date,
    FORMAT(GETDATE(), 'yyyy-MM-dd') as iso_format,
    FORMAT(GETDATE(), 'dd/MM/yyyy') as uk_format,
    FORMAT(GETDATE(), 'MM/dd/yyyy') as us_format,
    FORMAT(GETDATE(), 'MMMM dd, yyyy') as long_format,
    CONVERT(VARCHAR(10), GETDATE(), 120) as iso_convert,
    CONVERT(VARCHAR(10), GETDATE(), 103) as uk_convert,
    CONVERT(VARCHAR(10), GETDATE(), 101) as us_convert;

-- =====================================================================
-- 2. DATE ARITHMETIC AND CALCULATIONS
-- =====================================================================

-- Date addition and subtraction
WITH date_calculations AS (
    SELECT GETDATE() as base_date
)
SELECT 
    base_date,
    DATEADD(DAY, 7, base_date) as add_7_days,
    DATEADD(MONTH, 1, base_date) as add_1_month,
    DATEADD(YEAR, -1, base_date) as subtract_1_year,
    DATEADD(HOUR, 24, base_date) as add_24_hours,
    DATEADD(MINUTE, -30, base_date) as subtract_30_minutes,
    DATEADD(QUARTER, 2, base_date) as add_2_quarters
FROM date_calculations;

-- Date difference calculations
WITH date_ranges AS (
    SELECT 
        '2023-01-01' as start_date,
        '2023-12-31' as end_date,
        '2023-06-15' as middle_date
)
SELECT 
    start_date,
    end_date,
    middle_date,
    DATEDIFF(DAY, start_date, end_date) as days_difference,
    DATEDIFF(MONTH, start_date, end_date) as months_difference,
    DATEDIFF(WEEK, start_date, end_date) as weeks_difference,
    DATEDIFF(HOUR, start_date, middle_date) as hours_to_middle,
    DATEDIFF(YEAR, start_date, end_date) as years_difference
FROM date_ranges;

-- =====================================================================
-- 3. DATE PARTS AND EXTRACTION
-- =====================================================================

-- Extract various parts of dates
WITH sample_dates AS (
    SELECT 
        '2023-03-15 14:30:45.123' as sample_datetime,
        '2023-12-31' as year_end,
        '2023-02-28' as feb_28,
        '2024-02-29' as leap_day
)
SELECT 
    sample_datetime,
    YEAR(sample_datetime) as year_part,
    MONTH(sample_datetime) as month_part,
    DAY(sample_datetime) as day_part,
    DATEPART(HOUR, sample_datetime) as hour_part,
    DATEPART(MINUTE, sample_datetime) as minute_part,
    DATEPART(SECOND, sample_datetime) as second_part,
    DATEPART(MILLISECOND, sample_datetime) as millisecond_part,
    DATEPART(WEEKDAY, sample_datetime) as weekday_number,
    DATENAME(WEEKDAY, sample_datetime) as weekday_name,
    DATENAME(MONTH, sample_datetime) as month_name,
    DATEPART(QUARTER, sample_datetime) as quarter,
    DATEPART(DAYOFYEAR, sample_datetime) as day_of_year,
    DATEPART(WEEK, sample_datetime) as week_of_year,
    DATEPART(ISO_WEEK, sample_datetime) as iso_week
FROM sample_dates;

-- =====================================================================
-- 4. EDGE CASES AND BOUNDARY CONDITIONS
-- =====================================================================

-- Leap year handling
WITH leap_year_tests AS (
    SELECT year_val, 
           CASE 
               WHEN (year_val % 4 = 0 AND year_val % 100 != 0) OR (year_val % 400 = 0) 
               THEN 'Leap Year' 
               ELSE 'Not Leap Year' 
           END as leap_year_status,
           CASE 
               WHEN ISDATE(CAST(year_val as VARCHAR(4)) + '-02-29') = 1 
               THEN 'Feb 29 Valid' 
               ELSE 'Feb 29 Invalid' 
           END as feb_29_validity
    FROM (VALUES (2020), (2021), (2022), (2023), (2024), (1900), (2000)) as years(year_val)
)
SELECT * FROM leap_year_tests;

-- Month end date calculations (handle different month lengths)
WITH month_ends AS (
    SELECT month_num,
           EOMONTH(CAST('2023-' + RIGHT('0' + CAST(month_num as VARCHAR(2)), 2) + '-01' as DATE)) as month_end_2023,
           EOMONTH(CAST('2024-' + RIGHT('0' + CAST(month_num as VARCHAR(2)), 2) + '-01' as DATE)) as month_end_2024_leap,
           DAY(EOMONTH(CAST('2023-' + RIGHT('0' + CAST(month_num as VARCHAR(2)), 2) + '-01' as DATE))) as days_in_month_2023,
           DAY(EOMONTH(CAST('2024-' + RIGHT('0' + CAST(month_num as VARCHAR(2)), 2) + '-01' as DATE))) as days_in_month_2024
    FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) as months(month_num)
)
SELECT * FROM month_ends;

-- Time zone edge cases (daylight saving transitions)
WITH timezone_scenarios AS (
    SELECT 
        '2023-03-12 01:30:00' as before_dst,  -- Spring forward
        '2023-03-12 03:30:00' as after_dst,
        '2023-11-05 01:30:00' as before_std,  -- Fall back
        '2023-11-05 02:30:00' as after_std
)
SELECT 
    before_dst,
    after_dst,
    DATEDIFF(HOUR, before_dst, after_dst) as spring_hour_diff,
    before_std,
    after_std,
    DATEDIFF(HOUR, before_std, after_std) as fall_hour_diff
FROM timezone_scenarios;

-- =====================================================================
-- 5. BUSINESS DATE CALCULATIONS
-- =====================================================================

-- Calculate business days (excluding weekends)
WITH business_date_calc AS (
    SELECT 
        '2023-11-01' as start_date,
        '2023-11-30' as end_date
),
date_series AS (
    SELECT start_date as current_date, end_date
    FROM business_date_calc
    
    UNION ALL
    
    SELECT DATEADD(DAY, 1, current_date), end_date
    FROM date_series
    WHERE current_date < end_date
)
SELECT 
    COUNT(*) as total_days,
    COUNT(CASE WHEN DATEPART(WEEKDAY, current_date) NOT IN (1, 7) THEN 1 END) as business_days,
    COUNT(CASE WHEN DATEPART(WEEKDAY, current_date) IN (1, 7) THEN 1 END) as weekend_days
FROM date_series
OPTION (MAXRECURSION 100);

-- First and last day of month/quarter/year
WITH date_boundaries AS (
    SELECT '2023-07-15' as sample_date
)
SELECT 
    sample_date,
    -- Month boundaries
    DATEFROMPARTS(YEAR(sample_date), MONTH(sample_date), 1) as first_day_of_month,
    EOMONTH(sample_date) as last_day_of_month,
    -- Quarter boundaries
    DATEFROMPARTS(YEAR(sample_date), ((DATEPART(QUARTER, sample_date) - 1) * 3) + 1, 1) as first_day_of_quarter,
    EOMONTH(DATEFROMPARTS(YEAR(sample_date), DATEPART(QUARTER, sample_date) * 3, 1)) as last_day_of_quarter,
    -- Year boundaries
    DATEFROMPARTS(YEAR(sample_date), 1, 1) as first_day_of_year,
    DATEFROMPARTS(YEAR(sample_date), 12, 31) as last_day_of_year
FROM date_boundaries;

-- =====================================================================
-- 6. DATE VALIDATION AND ERROR HANDLING
-- =====================================================================

-- Date validation scenarios
WITH date_validation_tests AS (
    SELECT test_date, test_description
    FROM (VALUES 
        ('2023-02-29', 'Invalid date - Feb 29 in non-leap year'),
        ('2024-02-29', 'Valid date - Feb 29 in leap year'),
        ('2023-13-01', 'Invalid month'),
        ('2023-12-32', 'Invalid day'),
        ('2023-04-31', 'Invalid day for April'),
        ('2023-12-31', 'Valid date'),
        ('', 'Empty string'),
        ('abc', 'Non-date string'),
        ('2023/12/31', 'Different format')
    ) as tests(test_date, test_description)
)
SELECT 
    test_date,
    test_description,
    ISDATE(test_date) as is_valid_date,
    CASE 
        WHEN ISDATE(test_date) = 1 
        THEN TRY_CAST(test_date as DATE)
        ELSE NULL 
    END as converted_date
FROM date_validation_tests;

-- Handle NULL dates and edge cases
WITH null_date_scenarios AS (
    SELECT scenario, date_value
    FROM (VALUES 
        ('Normal date', '2023-12-31'),
        ('NULL date', NULL),
        ('Empty string', ''),
        ('Min date', '1753-01-01'),  -- SQL Server minimum date
        ('Max date', '9999-12-31')   -- SQL Server maximum date
    ) as scenarios(scenario, date_value)
)
SELECT 
    scenario,
    date_value,
    ISNULL(TRY_CAST(date_value as DATE), '1900-01-01') as date_with_default,
    COALESCE(TRY_CAST(date_value as DATE), GETDATE()) as date_with_current_default,
    CASE 
        WHEN TRY_CAST(date_value as DATE) IS NULL 
        THEN 'Invalid/NULL date'
        ELSE 'Valid date'
    END as validation_status
FROM null_date_scenarios;

-- =====================================================================
-- 7. ADVANCED DATE SCENARIOS FOR INTERVIEWS
-- =====================================================================

-- Find overlapping date ranges
WITH date_ranges AS (
    SELECT range_id, start_date, end_date
    FROM (VALUES 
        (1, '2023-01-01', '2023-03-31'),
        (2, '2023-02-15', '2023-05-31'),
        (3, '2023-06-01', '2023-08-31'),
        (4, '2023-07-15', '2023-09-30')
    ) as ranges(range_id, start_date, end_date)
)
SELECT 
    r1.range_id as range1_id,
    r1.start_date as range1_start,
    r1.end_date as range1_end,
    r2.range_id as range2_id,
    r2.start_date as range2_start,
    r2.end_date as range2_end,
    CASE 
        WHEN r1.start_date <= r2.end_date AND r1.end_date >= r2.start_date
        THEN 'Overlapping'
        ELSE 'Non-overlapping'
    END as overlap_status,
    CASE 
        WHEN r1.start_date <= r2.end_date AND r1.end_date >= r2.start_date
        THEN DATEDIFF(DAY, 
            CASE WHEN r1.start_date > r2.start_date THEN r1.start_date ELSE r2.start_date END,
            CASE WHEN r1.end_date < r2.end_date THEN r1.end_date ELSE r2.end_date END
        ) + 1
        ELSE 0
    END as overlap_days
FROM date_ranges r1
CROSS JOIN date_ranges r2
WHERE r1.range_id < r2.range_id;

-- Calculate running date sequences and gaps
WITH date_sequence AS (
    SELECT date_val
    FROM (VALUES 
        ('2023-01-01'),
        ('2023-01-02'),
        ('2023-01-03'),
        ('2023-01-05'),  -- Gap here
        ('2023-01-06'),
        ('2023-01-08'),  -- Gap here
        ('2023-01-09'),
        ('2023-01-10')
    ) as dates(date_val)
),
date_gaps AS (
    SELECT 
        date_val,
        LAG(date_val) OVER (ORDER BY date_val) as prev_date,
        DATEDIFF(DAY, LAG(date_val) OVER (ORDER BY date_val), date_val) as days_gap
    FROM date_sequence
)
SELECT 
    date_val,
    prev_date,
    days_gap,
    CASE 
        WHEN days_gap > 1 THEN 'Gap detected'
        WHEN days_gap = 1 THEN 'Consecutive'
        WHEN prev_date IS NULL THEN 'First date'
        ELSE 'Same date'
    END as sequence_status
FROM date_gaps
ORDER BY date_val;

-- Age calculation with edge cases
WITH age_calculations AS (
    SELECT person_id, birth_date, calculation_date
    FROM (VALUES 
        (1, '1990-03-15', '2023-03-14'),  -- Day before birthday
        (2, '1990-03-15', '2023-03-15'),  -- Exact birthday
        (3, '1990-03-15', '2023-03-16'),  -- Day after birthday
        (4, '2000-02-29', '2023-02-28'),  -- Leap year birth, non-leap calculation
        (5, '2000-02-29', '2024-02-29'),  -- Leap year birth, leap calculation
        (6, '1985-12-31', '2023-01-01')   -- Year boundary
    ) as people(person_id, birth_date, calculation_date)
)
SELECT 
    person_id,
    birth_date,
    calculation_date,
    DATEDIFF(YEAR, birth_date, calculation_date) as simple_age,
    CASE 
        WHEN DATEADD(YEAR, DATEDIFF(YEAR, birth_date, calculation_date), birth_date) > calculation_date
        THEN DATEDIFF(YEAR, birth_date, calculation_date) - 1
        ELSE DATEDIFF(YEAR, birth_date, calculation_date)
    END as accurate_age,
    DATEDIFF(DAY, birth_date, calculation_date) as total_days_lived
FROM age_calculations;

-- =====================================================================
-- 8. PERFORMANCE CONSIDERATIONS
-- =====================================================================

-- Efficient date range queries (using SARGable predicates)
-- Good practices for date filtering

-- GOOD: SARGable (Search ARGument able)
SELECT 'SARGable Examples' as query_type;
-- WHERE date_column >= '2023-01-01' AND date_column < '2024-01-01'
-- WHERE date_column >= DATEADD(DAY, -30, GETDATE())

-- BAD: Non-SARGable (functions on column side)
SELECT 'Non-SARGable Examples (AVOID)' as query_type;
-- WHERE YEAR(date_column) = 2023
-- WHERE DATEPART(MONTH, date_column) = 12
-- WHERE DATEDIFF(DAY, date_column, GETDATE()) = 30

-- =====================================================================
-- 9. COMMON INTERVIEW QUESTIONS WITH SOLUTIONS
-- =====================================================================

-- Question: Find all Mondays in a given month
WITH mondays_in_month AS (
    SELECT '2023-12-01' as month_start,
           EOMONTH('2023-12-01') as month_end
),
all_dates AS (
    SELECT month_start as current_date, month_end
    FROM mondays_in_month
    
    UNION ALL
    
    SELECT DATEADD(DAY, 1, current_date), month_end
    FROM all_dates
    WHERE current_date < month_end
)
SELECT current_date as monday_date
FROM all_dates
WHERE DATEPART(WEEKDAY, current_date) = 2  -- Monday
ORDER BY current_date
OPTION (MAXRECURSION 100);

-- Question: Calculate retention rate by month
WITH sample_user_activity AS (
    SELECT user_id, activity_date
    FROM (VALUES 
        (1, '2023-01-15'),
        (1, '2023-02-20'),
        (1, '2023-03-10'),
        (2, '2023-01-10'),
        (2, '2023-02-15'),
        (3, '2023-01-05'),
        (3, '2023-03-25')
    ) as activity(user_id, activity_date)
),
monthly_activity AS (
    SELECT 
        user_id,
        YEAR(activity_date) as year_val,
        MONTH(activity_date) as month_val,
        DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1) as month_start
    FROM sample_user_activity
),
user_months AS (
    SELECT 
        user_id,
        month_start,
        LAG(month_start) OVER (PARTITION BY user_id ORDER BY month_start) as prev_month
    FROM monthly_activity
)
SELECT 
    month_start,
    COUNT(DISTINCT user_id) as total_active_users,
    COUNT(DISTINCT CASE 
        WHEN DATEDIFF(MONTH, prev_month, month_start) = 1 
        THEN user_id 
    END) as retained_users,
    CAST(COUNT(DISTINCT CASE 
        WHEN DATEDIFF(MONTH, prev_month, month_start) = 1 
        THEN user_id 
    END) * 100.0 / NULLIF(COUNT(DISTINCT user_id), 0) as DECIMAL(5,2)) as retention_rate_percent
FROM user_months
GROUP BY month_start
ORDER BY month_start;
