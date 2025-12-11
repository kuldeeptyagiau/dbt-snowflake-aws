-- =====================================================================
-- SAMPLE DATASETS AND PERFORMANCE OPTIMIZATION FOR DATE QUERIES
-- Test data and performance tuning examples for interview preparation
-- =====================================================================

-- =====================================================================
-- 1. SAMPLE DATASET CREATION
-- =====================================================================

-- Create comprehensive test datasets for practicing date queries
-- These can be used with any of the date query examples

-- Sample Customers Table with Date Fields
CREATE OR REPLACE TABLE sample_customers AS
SELECT 
    customer_id,
    customer_name,
    email,
    registration_date,
    last_login_date,
    birth_date,
    status,
    country,
    timezone
FROM VALUES 
    (1, 'John Smith', 'john@email.com', '2023-01-15'::DATE, '2023-12-01 10:30:00'::TIMESTAMP, '1985-03-20'::DATE, 'Active', 'USA', 'America/New_York'),
    (2, 'Jane Doe', 'jane@email.com', '2023-02-20'::DATE, '2023-12-02 14:15:00'::TIMESTAMP, '1990-07-15'::DATE, 'Active', 'UK', 'Europe/London'),
    (3, 'Bob Wilson', 'bob@email.com', '2023-03-10'::DATE, '2023-11-25 09:45:00'::TIMESTAMP, '1988-12-03'::DATE, 'Inactive', 'Canada', 'America/Toronto'),
    (4, 'Alice Johnson', 'alice@email.com', '2023-01-05'::DATE, '2023-12-03 16:20:00'::TIMESTAMP, '1992-09-28'::DATE, 'Active', 'Australia', 'Australia/Sydney'),
    (5, 'Charlie Brown', 'charlie@email.com', '2023-04-12'::DATE, '2023-11-30 11:00:00'::TIMESTAMP, '1987-02-14'::DATE, 'Active', 'USA', 'America/Los_Angeles'),
    (6, 'Diana Prince', 'diana@email.com', '2023-05-08'::DATE, '2023-12-01 13:30:00'::TIMESTAMP, '1991-11-22'::DATE, 'Active', 'Germany', 'Europe/Berlin'),
    (7, 'Eva Martinez', 'eva@email.com', '2023-06-22'::DATE, '2023-11-28 08:15:00'::TIMESTAMP, '1989-06-10'::DATE, 'Inactive', 'Spain', 'Europe/Madrid'),
    (8, 'Frank Chen', 'frank@email.com', '2023-07-03'::DATE, '2023-12-02 19:45:00'::TIMESTAMP, '1986-04-18'::DATE, 'Active', 'China', 'Asia/Shanghai'),
    (9, 'Grace Kim', 'grace@email.com', '2023-08-14'::DATE, '2023-12-01 07:30:00'::TIMESTAMP, '1993-01-05'::DATE, 'Active', 'South Korea', 'Asia/Seoul'),
    (10, 'Henry Taylor', 'henry@email.com', '2023-09-25'::DATE, '2023-11-29 12:00:00'::TIMESTAMP, '1984-08-30'::DATE, 'Active', 'UK', 'Europe/London')
as customers(customer_id, customer_name, email, registration_date, last_login_date, birth_date, status, country, timezone);

-- Sample Orders Table with Complex Date Scenarios
CREATE OR REPLACE TABLE sample_orders AS
WITH date_generator AS (
    SELECT 
        DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2023-01-01'::DATE) as order_date
    FROM TABLE(GENERATOR(ROWCOUNT => 365))
),
order_data AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY order_date, RANDOM()) as order_id,
        order_date,
        order_date + INTERVAL (FLOOR(RANDOM() * 24) || ' hours') as created_timestamp,
        DATEADD(DAY, FLOOR(RANDOM() * 7) + 1, order_date) as shipped_date,
        DATEADD(DAY, FLOOR(RANDOM() * 14) + 3, order_date) as delivered_date,
        FLOOR(RANDOM() * 10) + 1 as customer_id,
        ROUND(RANDOM() * 1000 + 50, 2) as order_amount,
        CASE FLOOR(RANDOM() * 5)
            WHEN 0 THEN 'pending'
            WHEN 1 THEN 'confirmed'
            WHEN 2 THEN 'shipped'
            WHEN 3 THEN 'delivered'
            ELSE 'cancelled'
        END as order_status
    FROM date_generator
)
SELECT 
    order_id,
    customer_id,
    order_date,
    created_timestamp,
    -- Add some realistic business logic
    CASE 
        WHEN order_status = 'cancelled' THEN NULL
        WHEN DAYOFWEEK(order_date) IN (0, 6) THEN DATEADD(DAY, 2, shipped_date) -- Weekend delay
        ELSE shipped_date
    END as shipped_date,
    CASE 
        WHEN order_status IN ('cancelled', 'pending', 'confirmed') THEN NULL
        ELSE delivered_date
    END as delivered_date,
    order_amount,
    order_status
FROM order_data
LIMIT 1000;

-- Sample Events Table for Session Analysis
CREATE OR REPLACE TABLE sample_events AS
WITH user_sessions AS (
    SELECT 
        user_id,
        session_start,
        DATEADD(MINUTE, FLOOR(RANDOM() * 120) + 5, session_start) as session_end
    FROM (
        SELECT 
            FLOOR(RANDOM() * 10) + 1 as user_id,
            DATEADD(HOUR, FLOOR(RANDOM() * 24), 
                DATEADD(DAY, FLOOR(RANDOM() * 30), '2023-11-01'::DATE)) as session_start
        FROM TABLE(GENERATOR(ROWCOUNT => 500))
    )
),
events AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY event_timestamp) as event_id,
        user_id,
        event_timestamp,
        event_type,
        page_url
    FROM (
        SELECT 
            user_id,
            session_start + INTERVAL (FLOOR(RANDOM() * DATEDIFF(MINUTE, session_start, session_end)) || ' minutes') as event_timestamp,
            CASE FLOOR(RANDOM() * 5)
                WHEN 0 THEN 'login'
                WHEN 1 THEN 'page_view'
                WHEN 2 THEN 'click'
                WHEN 3 THEN 'purchase'
                ELSE 'logout'
            END as event_type,
            CASE FLOOR(RANDOM() * 6)
                WHEN 0 THEN '/home'
                WHEN 1 THEN '/products'
                WHEN 2 THEN '/cart'
                WHEN 3 THEN '/checkout'
                WHEN 4 THEN '/profile'
                ELSE '/help'
            END as page_url
        FROM user_sessions,
        TABLE(GENERATOR(ROWCOUNT => 5)) -- 5 events per session on average
    )
)
SELECT * FROM events;

-- Sample Time Series Data for Metrics Analysis
CREATE OR REPLACE TABLE sample_metrics AS
WITH date_range AS (
    SELECT 
        DATEADD(HOUR, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2023-01-01 00:00:00'::TIMESTAMP) as metric_timestamp
    FROM TABLE(GENERATOR(ROWCOUNT => 8760)) -- One year of hourly data
)
SELECT 
    metric_timestamp,
    DATE_TRUNC('day', metric_timestamp) as metric_date,
    DATE_PART('hour', metric_timestamp) as metric_hour,
    -- Simulate realistic business metrics with seasonality
    ROUND(
        1000 + 
        200 * SIN(DATE_PART('dayofyear', metric_timestamp) * 2 * PI() / 365) + -- Yearly seasonality
        50 * SIN(DATE_PART('hour', metric_timestamp) * 2 * PI() / 24) +        -- Daily seasonality
        100 * SIN(DATE_PART('dayofweek', metric_timestamp) * 2 * PI() / 7) +   -- Weekly seasonality
        RANDOM() * 100, -- Random noise
        2
    ) as daily_revenue,
    ROUND(
        50 + 
        10 * SIN(DATE_PART('dayofyear', metric_timestamp) * 2 * PI() / 365) +
        5 * SIN(DATE_PART('hour', metric_timestamp) * 2 * PI() / 24) +
        RANDOM() * 20,
        0
    ) as active_users,
    ROUND(RANDOM() * 10, 0) as error_count
FROM date_range;

-- =====================================================================
-- 2. PERFORMANCE OPTIMIZATION EXAMPLES
-- =====================================================================

-- Example 1: Efficient Date Range Filtering
-- This demonstrates SARGable vs non-SARGable predicates

-- ❌ BAD: Non-SARGable (prevents index usage)
/*
SELECT * FROM sample_orders 
WHERE YEAR(order_date) = 2023 
  AND MONTH(order_date) = 12;

SELECT * FROM sample_orders 
WHERE DATE_PART('quarter', order_date) = 4;

SELECT * FROM sample_orders 
WHERE DAYOFWEEK(order_date) = 1; -- Monday
*/

-- ✅ GOOD: SARGable (allows index usage)
SELECT * FROM sample_orders 
WHERE order_date >= '2023-12-01'::DATE 
  AND order_date < '2024-01-01'::DATE;

SELECT * FROM sample_orders 
WHERE order_date >= '2023-10-01'::DATE 
  AND order_date < '2024-01-01'::DATE; -- Q4 2023

-- For day-of-week filtering, use a more complex but SARGable approach
WITH mondays_2023 AS (
    SELECT 
        DATEADD(DAY, (ROW_NUMBER() OVER (ORDER BY NULL) - 1) * 7, '2023-01-02'::DATE) as monday_date
    FROM TABLE(GENERATOR(ROWCOUNT => 52))
    WHERE DATEADD(DAY, (ROW_NUMBER() OVER (ORDER BY NULL) - 1) * 7, '2023-01-02'::DATE) < '2024-01-01'::DATE
)
SELECT o.* 
FROM sample_orders o
INNER JOIN mondays_2023 m ON o.order_date = m.monday_date;

-- Example 2: Optimizing Window Functions with Date Partitioning
-- Show the difference between efficient and inefficient window function usage

-- ❌ Less efficient: Large unbounded window
SELECT 
    order_date,
    customer_id,
    order_amount,
    SUM(order_amount) OVER (ORDER BY order_date) as running_total_all_customers
FROM sample_orders
ORDER BY order_date;

-- ✅ More efficient: Partitioned windows
SELECT 
    order_date,
    customer_id,
    order_amount,
    SUM(order_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY order_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) as rolling_30_order_total,
    AVG(order_amount) OVER (
        PARTITION BY DATE_TRUNC('month', order_date)
        ORDER BY order_date
    ) as monthly_avg
FROM sample_orders
ORDER BY customer_id, order_date;

-- Example 3: Efficient Date Dimension Join
-- Create a date dimension table for better performance

CREATE OR REPLACE TABLE date_dimension AS
SELECT 
    date_value,
    YEAR(date_value) as year,
    MONTH(date_value) as month,
    DAY(date_value) as day,
    DATE_PART('quarter', date_value) as quarter,
    DAYOFWEEK(date_value) as day_of_week,
    DAYNAME(date_value) as day_name,
    MONTHNAME(date_value) as month_name,
    CASE WHEN DAYOFWEEK(date_value) IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END as day_type,
    CASE WHEN DAYOFWEEK(date_value) BETWEEN 1 AND 5 THEN 1 ELSE 0 END as is_business_day,
    -- Holiday flags (simplified example)
    CASE 
        WHEN DATE_PART('month', date_value) = 1 AND DATE_PART('day', date_value) = 1 THEN 1
        WHEN DATE_PART('month', date_value) = 7 AND DATE_PART('day', date_value) = 4 THEN 1
        WHEN DATE_PART('month', date_value) = 12 AND DATE_PART('day', date_value) = 25 THEN 1
        ELSE 0
    END as is_holiday
FROM (
    SELECT 
        DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2020-01-01'::DATE) as date_value
    FROM TABLE(GENERATOR(ROWCOUNT => 2000)) -- 5+ years of dates
    WHERE DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2020-01-01'::DATE) < '2025-12-31'::DATE
);

-- ✅ Efficient join with pre-calculated date dimension
SELECT 
    d.year,
    d.quarter,
    d.month_name,
    d.day_type,
    COUNT(*) as order_count,
    SUM(o.order_amount) as total_revenue,
    AVG(o.order_amount) as avg_order_value
FROM sample_orders o
INNER JOIN date_dimension d ON o.order_date = d.date_value
WHERE d.is_business_day = 1  -- Only business days
  AND d.is_holiday = 0       -- Exclude holidays
GROUP BY d.year, d.quarter, d.month_name, d.day_type
ORDER BY d.year, d.quarter;

-- Example 4: Optimizing Complex Date Calculations
-- Show how to optimize complex date logic

-- ❌ Inefficient: Multiple date calculations
SELECT 
    customer_id,
    order_date,
    order_amount,
    -- Repeated calculations
    DATEDIFF('day', LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), order_date) as days_since_last_order,
    CASE 
        WHEN DATEDIFF('day', LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), order_date) <= 30 
        THEN 'Active'
        ELSE 'Inactive'
    END as customer_status
FROM sample_orders;

-- ✅ Efficient: Calculate once, reuse
WITH order_intervals AS (
    SELECT 
        customer_id,
        order_date,
        order_amount,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as prev_order_date
    FROM sample_orders
),
order_analysis AS (
    SELECT 
        *,
        DATEDIFF('day', prev_order_date, order_date) as days_since_last_order
    FROM order_intervals
)
SELECT 
    customer_id,
    order_date,
    order_amount,
    days_since_last_order,
    CASE 
        WHEN days_since_last_order <= 30 OR days_since_last_order IS NULL
        THEN 'Active'
        ELSE 'Inactive'
    END as customer_status
FROM order_analysis;

-- =====================================================================
-- 3. INDEXING STRATEGIES FOR DATE COLUMNS
-- =====================================================================

-- Examples of efficient indexing for date-heavy queries
-- Note: These are conceptual examples - actual implementation depends on your database

/*
-- Clustered index on frequently filtered date column
ALTER TABLE sample_orders CLUSTER BY (order_date);

-- Composite index for multi-column date filtering
CREATE INDEX idx_orders_customer_date ON sample_orders (customer_id, order_date);

-- Partial index for specific date ranges
CREATE INDEX idx_orders_recent ON sample_orders (order_date) 
WHERE order_date >= '2023-01-01'::DATE;

-- Covering index to avoid key lookups
CREATE INDEX idx_orders_covering ON sample_orders (order_date) 
INCLUDE (customer_id, order_amount, order_status);
*/

-- =====================================================================
-- 4. QUERY OPTIMIZATION PATTERNS
-- =====================================================================

-- Pattern 1: Use LIMIT with ORDER BY for top-N queries
-- ✅ Efficient for finding recent orders
SELECT customer_id, order_date, order_amount
FROM sample_orders 
WHERE customer_id = 5
ORDER BY order_date DESC 
LIMIT 10;

-- Pattern 2: Use EXISTS instead of IN for date-based filtering
-- ✅ More efficient for large datasets
SELECT c.customer_id, c.customer_name
FROM sample_customers c
WHERE EXISTS (
    SELECT 1 FROM sample_orders o 
    WHERE o.customer_id = c.customer_id 
      AND o.order_date >= CURRENT_DATE - 30
);

-- Pattern 3: Use appropriate aggregation levels
-- ✅ Aggregate at the right granularity
SELECT 
    DATE_TRUNC('week', order_date) as week_start,
    COUNT(*) as orders_count,
    SUM(order_amount) as week_revenue
FROM sample_orders
WHERE order_date >= CURRENT_DATE - 90  -- Last 90 days
GROUP BY DATE_TRUNC('week', order_date)
ORDER BY week_start;

-- =====================================================================
-- 5. MONITORING AND DEBUGGING DATE QUERIES
-- =====================================================================

-- Query to analyze date distribution in your data
SELECT 
    'sample_orders' as table_name,
    'order_date' as column_name,
    MIN(order_date) as min_date,
    MAX(order_date) as max_date,
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_date) as distinct_dates,
    COUNT(CASE WHEN order_date IS NULL THEN 1 END) as null_count,
    DATEDIFF('day', MIN(order_date), MAX(order_date)) as date_range_days
FROM sample_orders

UNION ALL

SELECT 
    'sample_customers',
    'registration_date',
    MIN(registration_date),
    MAX(registration_date),
    COUNT(*),
    COUNT(DISTINCT registration_date),
    COUNT(CASE WHEN registration_date IS NULL THEN 1 END),
    DATEDIFF('day', MIN(registration_date), MAX(registration_date))
FROM sample_customers;

-- Query to find potential date quality issues
SELECT 
    'Future dates in orders' as issue_type,
    COUNT(*) as issue_count
FROM sample_orders 
WHERE order_date > CURRENT_DATE

UNION ALL

SELECT 
    'Orders before customer registration',
    COUNT(*)
FROM sample_orders o
INNER JOIN sample_customers c ON o.customer_id = c.customer_id
WHERE o.order_date < c.registration_date

UNION ALL

SELECT 
    'Shipped before ordered',
    COUNT(*)
FROM sample_orders
WHERE shipped_date < order_date

UNION ALL

SELECT 
    'Delivered before shipped',
    COUNT(*)
FROM sample_orders
WHERE delivered_date < shipped_date;

-- Performance analysis query
SELECT 
    query_type,
    execution_time_estimate,
    optimization_notes
FROM VALUES 
    ('SELECT with date range filter', 'Fast with index', 'Use SARGable predicates'),
    ('Window function with date partition', 'Medium', 'Consider smaller partitions'),
    ('Complex date calculations', 'Slow without optimization', 'Pre-calculate in CTEs'),
    ('Cross-timezone conversions', 'Medium', 'Cache timezone data'),
    ('Recursive date series', 'Variable', 'Limit recursion depth')
as performance_guide(query_type, execution_time_estimate, optimization_notes);
