-- =====================================================================
-- DATA ENGINEERING EDGE CASES AND CHALLENGING SCENARIOS
-- Real-world interview questions and complex data scenarios
-- =====================================================================

-- =====================================================================
-- 1. TIME ZONE AND DAYLIGHT SAVING EDGE CASES
-- =====================================================================

-- Scenario: Handle data from multiple time zones with DST transitions
WITH timezone_data AS (
    SELECT event_timestamp, event_timezone, event_description
    FROM VALUES 
        -- Spring forward scenario (lose an hour)
        ('2023-03-12 01:30:00', 'America/New_York', 'Before DST'),
        ('2023-03-12 03:30:00', 'America/New_York', 'After DST spring forward'),
        -- Fall back scenario (gain an hour)
        ('2023-11-05 01:30:00', 'America/New_York', 'Before standard time'),
        ('2023-11-05 02:30:00', 'America/New_York', 'After fall back'),
        -- Different timezone
        ('2023-03-12 06:30:00', 'UTC', 'UTC time during NY DST transition'),
        ('2023-11-05 06:30:00', 'UTC', 'UTC time during NY standard transition')
    as events(event_timestamp, event_timezone, event_description)
)
SELECT 
    event_timestamp,
    event_timezone,
    event_description,
    -- Convert all to UTC for comparison
    CASE 
        WHEN event_timezone = 'UTC' THEN event_timestamp::TIMESTAMP
        ELSE CONVERT_TIMEZONE(event_timezone, 'UTC', event_timestamp::TIMESTAMP)
    END as utc_timestamp,
    -- Convert to a common timezone
    CASE 
        WHEN event_timezone = 'UTC' THEN 
            CONVERT_TIMEZONE('UTC', 'America/New_York', event_timestamp::TIMESTAMP)
        ELSE event_timestamp::TIMESTAMP
    END as ny_timestamp
FROM timezone_data
ORDER BY utc_timestamp;

-- =====================================================================
-- 2. LATE ARRIVING DATA AND OUT-OF-ORDER PROCESSING
-- =====================================================================

-- Scenario: Handle events that arrive out of order or late
WITH event_stream AS (
    SELECT event_id, actual_event_time, processing_time, event_value
    FROM VALUES 
        (1, '2023-01-01 10:00:00'::TIMESTAMP, '2023-01-01 10:01:00'::TIMESTAMP, 100),
        (2, '2023-01-01 10:05:00'::TIMESTAMP, '2023-01-01 10:06:00'::TIMESTAMP, 150),
        (3, '2023-01-01 10:03:00'::TIMESTAMP, '2023-01-01 10:08:00'::TIMESTAMP, 120), -- Late arrival
        (4, '2023-01-01 10:10:00'::TIMESTAMP, '2023-01-01 10:11:00'::TIMESTAMP, 200),
        (5, '2023-01-01 10:02:00'::TIMESTAMP, '2023-01-01 10:15:00'::TIMESTAMP, 80),  -- Very late arrival
        (6, '2023-01-01 10:12:00'::TIMESTAMP, '2023-01-01 10:13:00'::TIMESTAMP, 180)
    as events(event_id, actual_event_time, processing_time, event_value)
)
SELECT 
    event_id,
    actual_event_time,
    processing_time,
    DATEDIFF('minute', actual_event_time, processing_time) as latency_minutes,
    event_value,
    -- Running sum by event time (correct order)
    SUM(event_value) OVER (ORDER BY actual_event_time ROWS UNBOUNDED PRECEDING) as correct_running_sum,
    -- Running sum by processing time (how system initially calculated)
    SUM(event_value) OVER (ORDER BY processing_time ROWS UNBOUNDED PRECEDING) as initial_processing_sum,
    -- Identify late arrivals
    CASE 
        WHEN DATEDIFF('minute', actual_event_time, processing_time) > 5 
        THEN 'Late Arrival'
        ELSE 'On Time'
    END as arrival_status
FROM event_stream
ORDER BY processing_time;

-- =====================================================================
-- 3. DATA QUALITY AND DEDUPLICATION CHALLENGES
-- =====================================================================

-- Scenario: Handle duplicate records with different strategies
WITH raw_user_data AS (
    SELECT user_id, email, first_name, last_name, registration_date, data_source
    FROM VALUES 
        (1, 'john@email.com', 'John', 'Smith', '2023-01-01'::DATE, 'web'),
        (1, 'john@email.com', 'John', 'Smith', '2023-01-01'::DATE, 'mobile'), -- Exact duplicate different source
        (1, 'john@gmail.com', 'John', 'Smith', '2023-01-02'::DATE, 'web'),   -- Same user, different email
        (2, 'jane@email.com', 'Jane', 'Doe', '2023-01-03'::DATE, 'web'),
        (2, 'jane@email.com', 'Jane', 'Johnson', '2023-01-04'::DATE, 'crm'), -- Same user, different last name
        (3, 'bob@email.com', 'Bob', 'Wilson', '2023-01-05'::DATE, 'web'),
        (3, 'bob@email.com', 'Bob', 'Wilson', '2023-01-05'::DATE, 'web')     -- Exact duplicate
    as users(user_id, email, first_name, last_name, registration_date, data_source)
),
deduplication_analysis AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY registration_date DESC, data_source) as rn_latest,
        ROW_NUMBER() OVER (PARTITION BY user_id, email ORDER BY registration_date DESC) as rn_email_latest,
        COUNT(*) OVER (PARTITION BY user_id) as duplicate_count,
        -- Hash for exact duplicate detection
        HASH(user_id, email, first_name, last_name, registration_date) as record_hash,
        COUNT(*) OVER (PARTITION BY HASH(user_id, email, first_name, last_name, registration_date)) as exact_duplicate_count
    FROM raw_user_data
)
SELECT 
    user_id,
    email,
    first_name,
    last_name,
    registration_date,
    data_source,
    duplicate_count,
    exact_duplicate_count,
    CASE 
        WHEN exact_duplicate_count > 1 THEN 'Exact Duplicate'
        WHEN duplicate_count > 1 THEN 'Potential Duplicate'
        ELSE 'Unique'
    END as duplicate_type,
    -- Different deduplication strategies
    CASE WHEN rn_latest = 1 THEN 'Keep - Latest by date' ELSE 'Remove' END as strategy_latest,
    CASE WHEN rn_email_latest = 1 THEN 'Keep - Latest by email' ELSE 'Remove' END as strategy_email_latest
FROM deduplication_analysis
ORDER BY user_id, registration_date;

-- =====================================================================
-- 4. WINDOW FUNCTION EDGE CASES
-- =====================================================================

-- Scenario: Complex window functions with edge cases
WITH sales_data AS (
    SELECT sales_date, salesperson, region, sales_amount
    FROM VALUES 
        ('2023-01-01', 'Alice', 'North', 1000),
        ('2023-01-01', 'Bob', 'North', 1500),
        ('2023-01-01', 'Carol', 'South', 800),
        ('2023-01-02', 'Alice', 'North', 1200),
        ('2023-01-02', 'Bob', 'North', 0),      -- Zero sales day
        ('2023-01-02', 'Carol', 'South', NULL), -- NULL sales
        ('2023-01-03', 'Alice', 'North', 1100),
        ('2023-01-03', 'David', 'South', 900),  -- New salesperson
        ('2023-01-04', 'Alice', 'North', 1300)
    as sales(sales_date, salesperson, region, sales_amount)
)
SELECT 
    sales_date,
    salesperson,
    region,
    sales_amount,
    -- Handle NULLs in window functions
    LAG(sales_amount) OVER (PARTITION BY salesperson ORDER BY sales_date) as prev_sales,
    LAG(sales_amount, 1, 0) OVER (PARTITION BY salesperson ORDER BY sales_date) as prev_sales_with_default,
    -- Moving average excluding NULLs
    AVG(sales_amount) OVER (
        PARTITION BY salesperson 
        ORDER BY sales_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as moving_avg_3days,
    -- Rank with ties
    RANK() OVER (PARTITION BY sales_date ORDER BY sales_amount DESC) as daily_rank,
    DENSE_RANK() OVER (PARTITION BY sales_date ORDER BY sales_amount DESC) as daily_dense_rank,
    ROW_NUMBER() OVER (PARTITION BY sales_date ORDER BY sales_amount DESC) as daily_row_num,
    -- Percentiles
    PERCENT_RANK() OVER (ORDER BY sales_amount) as percentile_rank,
    -- First and last value with frame
    FIRST_VALUE(sales_amount) OVER (
        PARTITION BY salesperson 
        ORDER BY sales_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as first_sale,
    LAST_VALUE(sales_amount) OVER (
        PARTITION BY salesperson 
        ORDER BY sales_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as last_sale
FROM sales_data
ORDER BY sales_date, salesperson;

-- =====================================================================
-- 5. HIERARCHICAL DATA AND RECURSIVE QUERIES
-- =====================================================================

-- Scenario: Organization hierarchy with complex relationships
WITH employee_hierarchy AS (
    SELECT employee_id, employee_name, manager_id, department, hire_date
    FROM VALUES 
        (1, 'CEO John', NULL, 'Executive', '2020-01-01'),
        (2, 'VP Sales Jane', 1, 'Sales', '2020-02-01'),
        (3, 'VP Eng Bob', 1, 'Engineering', '2020-02-01'),
        (4, 'Sales Mgr Alice', 2, 'Sales', '2020-03-01'),
        (5, 'Eng Mgr Carol', 3, 'Engineering', '2020-03-01'),
        (6, 'Sales Rep David', 4, 'Sales', '2020-04-01'),
        (7, 'Sales Rep Eve', 4, 'Sales', '2020-04-01'),
        (8, 'Engineer Frank', 5, 'Engineering', '2020-05-01'),
        (9, 'Engineer Grace', 5, 'Engineering', '2020-05-01'),
        (10, 'Senior Eng Henry', 3, 'Engineering', '2019-01-01'), -- Reports directly to VP
        (11, 'Intern Ivan', 8, 'Engineering', '2023-06-01')      -- Reports to Frank
    as employees(employee_id, employee_name, manager_id, department, hire_date)
),
hierarchy_cte AS (
    -- Anchor: Top level employees (no manager)
    SELECT 
        employee_id,
        employee_name,
        manager_id,
        department,
        hire_date,
        0 as level,
        employee_name as hierarchy_path,
        employee_id::VARCHAR as id_path
    FROM employee_hierarchy
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: employees with managers
    SELECT 
        e.employee_id,
        e.employee_name,
        e.manager_id,
        e.department,
        e.hire_date,
        h.level + 1,
        h.hierarchy_path || ' -> ' || e.employee_name as hierarchy_path,
        h.id_path || ',' || e.employee_id::VARCHAR as id_path
    FROM employee_hierarchy e
    INNER JOIN hierarchy_cte h ON e.manager_id = h.employee_id
)
SELECT 
    employee_id,
    employee_name,
    manager_id,
    department,
    level,
    hierarchy_path,
    -- Count direct reports
    (SELECT COUNT(*) FROM employee_hierarchy sub WHERE sub.manager_id = h.employee_id) as direct_reports,
    -- Count total subordinates
    (SELECT COUNT(*) FROM hierarchy_cte sub WHERE sub.id_path LIKE h.id_path || '%' AND sub.employee_id != h.employee_id) as total_subordinates,
    -- Find top level manager
    SPLIT_PART(id_path, ',', 1)::INT as top_level_manager_id
FROM hierarchy_cte h
ORDER BY level, employee_id;

-- =====================================================================
-- 6. SLOWLY CHANGING DIMENSIONS (SCD TYPE 2)
-- =====================================================================

-- Scenario: Track historical changes in customer data
WITH customer_changes AS (
    SELECT customer_id, customer_name, email, status, address, effective_date, source_system
    FROM VALUES 
        (100, 'John Smith', 'john@old.com', 'Active', '123 Main St', '2023-01-01'::DATE, 'CRM'),
        (100, 'John Smith', 'john@new.com', 'Active', '123 Main St', '2023-03-15'::DATE, 'CRM'),  -- Email change
        (100, 'John Smith', 'john@new.com', 'Active', '456 Oak Ave', '2023-06-01'::DATE, 'CRM'),  -- Address change
        (100, 'John Smith', 'john@new.com', 'Inactive', '456 Oak Ave', '2023-09-01'::DATE, 'CRM'), -- Status change
        (101, 'Jane Doe', 'jane@email.com', 'Active', '789 Pine St', '2023-02-01'::DATE, 'Web'),
        (101, 'Jane Johnson', 'jane@email.com', 'Active', '789 Pine St', '2023-05-01'::DATE, 'Web') -- Name change (marriage)
    as changes(customer_id, customer_name, email, status, address, effective_date, source_system)
),
scd_type2 AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        status,
        address,
        effective_date,
        source_system,
        -- Calculate end date for previous record
        LEAD(effective_date, 1, '9999-12-31'::DATE) OVER (
            PARTITION BY customer_id 
            ORDER BY effective_date
        ) as end_date,
        -- Version number
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY effective_date) as version,
        -- Current flag
        CASE 
            WHEN LEAD(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date) IS NULL 
            THEN 'Y' 
            ELSE 'N' 
        END as is_current,
        -- Identify what changed
        LAG(customer_name) OVER (PARTITION BY customer_id ORDER BY effective_date) as prev_name,
        LAG(email) OVER (PARTITION BY customer_id ORDER BY effective_date) as prev_email,
        LAG(status) OVER (PARTITION BY customer_id ORDER BY effective_date) as prev_status,
        LAG(address) OVER (PARTITION BY customer_id ORDER BY effective_date) as prev_address
    FROM customer_changes
)
SELECT 
    customer_id,
    customer_name,
    email,
    status,
    address,
    effective_date,
    end_date,
    version,
    is_current,
    DATEDIFF('day', effective_date, end_date) as days_active,
    -- What changed indicator
    CASE 
        WHEN prev_name IS NULL THEN 'Initial Record'
        WHEN customer_name != prev_name THEN 'Name Changed'
        WHEN email != prev_email THEN 'Email Changed'
        WHEN status != prev_status THEN 'Status Changed'
        WHEN address != prev_address THEN 'Address Changed'
        ELSE 'Other Change'
    END as change_reason
FROM scd_type2
ORDER BY customer_id, effective_date;

-- =====================================================================
-- 7. EVENT STREAMING AND SESSION ANALYSIS
-- =====================================================================

-- Scenario: Analyze user sessions from event stream
WITH user_events AS (
    SELECT user_id, event_timestamp, event_type, page_url
    FROM VALUES 
        (1, '2023-01-01 10:00:00'::TIMESTAMP, 'login', '/login'),
        (1, '2023-01-01 10:01:00'::TIMESTAMP, 'page_view', '/dashboard'),
        (1, '2023-01-01 10:05:00'::TIMESTAMP, 'page_view', '/products'),
        (1, '2023-01-01 10:08:00'::TIMESTAMP, 'logout', '/logout'),
        (1, '2023-01-01 14:30:00'::TIMESTAMP, 'login', '/login'),      -- New session
        (1, '2023-01-01 14:35:00'::TIMESTAMP, 'page_view', '/cart'),
        (1, '2023-01-01 14:40:00'::TIMESTAMP, 'purchase', '/checkout'),
        (2, '2023-01-01 11:00:00'::TIMESTAMP, 'login', '/login'),
        (2, '2023-01-01 11:02:00'::TIMESTAMP, 'page_view', '/products'),
        (2, '2023-01-01 11:35:00'::TIMESTAMP, 'page_view', '/help'),   -- 30+ min gap
        (2, '2023-01-01 11:36:00'::TIMESTAMP, 'logout', '/logout')
    as events(user_id, event_timestamp, event_type, page_url)
),
session_analysis AS (
    SELECT 
        user_id,
        event_timestamp,
        event_type,
        page_url,
        -- Calculate time between events
        LAG(event_timestamp) OVER (PARTITION BY user_id ORDER BY event_timestamp) as prev_event_time,
        DATEDIFF('minute', 
            LAG(event_timestamp) OVER (PARTITION BY user_id ORDER BY event_timestamp), 
            event_timestamp
        ) as minutes_since_prev_event,
        -- Session break identification (30+ minutes of inactivity)
        CASE 
            WHEN LAG(event_timestamp) OVER (PARTITION BY user_id ORDER BY event_timestamp) IS NULL 
                OR DATEDIFF('minute', LAG(event_timestamp) OVER (PARTITION BY user_id ORDER BY event_timestamp), event_timestamp) >= 30
            THEN 1 
            ELSE 0 
        END as session_start_flag
    FROM user_events
),
session_groups AS (
    SELECT 
        *,
        SUM(session_start_flag) OVER (
            PARTITION BY user_id 
            ORDER BY event_timestamp 
            ROWS UNBOUNDED PRECEDING
        ) as session_id
    FROM session_analysis
)
SELECT 
    user_id,
    session_id,
    MIN(event_timestamp) as session_start,
    MAX(event_timestamp) as session_end,
    DATEDIFF('minute', MIN(event_timestamp), MAX(event_timestamp)) as session_duration_minutes,
    COUNT(*) as event_count,
    COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) as page_views,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) as purchases,
    LISTAGG(DISTINCT event_type, ', ') WITHIN GROUP (ORDER BY event_timestamp) as event_types,
    CASE 
        WHEN COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) > 0 THEN 'Conversion'
        WHEN COUNT(*) = 1 THEN 'Bounce'
        ELSE 'Browse'
    END as session_type
FROM session_groups
GROUP BY user_id, session_id
ORDER BY user_id, session_id;

-- =====================================================================
-- 8. DATA PIPELINE MONITORING AND ANOMALY DETECTION
-- =====================================================================

-- Scenario: Monitor data pipeline health and detect anomalies
WITH pipeline_metrics AS (
    SELECT run_date, pipeline_name, records_processed, processing_time_minutes, error_count
    FROM VALUES 
        ('2023-01-01', 'daily_etl', 100000, 45, 0),
        ('2023-01-02', 'daily_etl', 102000, 47, 2),
        ('2023-01-03', 'daily_etl', 98000, 44, 1),
        ('2023-01-04', 'daily_etl', 105000, 48, 0),
        ('2023-01-05', 'daily_etl', 95000, 43, 1),
        ('2023-01-06', 'daily_etl', 15000, 25, 0),    -- Weekend anomaly - low volume
        ('2023-01-07', 'daily_etl', 12000, 22, 0),    -- Weekend anomaly - low volume
        ('2023-01-08', 'daily_etl', 101000, 46, 0),
        ('2023-01-09', 'daily_etl', 180000, 85, 15),  -- Anomaly - high volume, high processing time, high errors
        ('2023-01-10', 'daily_etl', 103000, 47, 1),
        ('2023-01-01', 'hourly_sync', 5000, 5, 0),
        ('2023-01-01', 'hourly_sync', 5200, 5, 0),
        ('2023-01-01', 'hourly_sync', 4800, 5, 0),
        ('2023-01-01', 'hourly_sync', 12000, 15, 5)   -- Anomaly in hourly job
    as metrics(run_date, pipeline_name, records_processed, processing_time_minutes, error_count)
),
anomaly_detection AS (
    SELECT 
        run_date,
        pipeline_name,
        records_processed,
        processing_time_minutes,
        error_count,
        -- Calculate moving averages and standard deviations
        AVG(records_processed) OVER (
            PARTITION BY pipeline_name 
            ORDER BY run_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ) as avg_records_7day,
        STDDEV(records_processed) OVER (
            PARTITION BY pipeline_name 
            ORDER BY run_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ) as stddev_records_7day,
        AVG(processing_time_minutes) OVER (
            PARTITION BY pipeline_name 
            ORDER BY run_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ) as avg_time_7day,
        STDDEV(processing_time_minutes) OVER (
            PARTITION BY pipeline_name 
            ORDER BY run_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ) as stddev_time_7day
    FROM pipeline_metrics
)
SELECT 
    run_date,
    pipeline_name,
    records_processed,
    processing_time_minutes,
    error_count,
    avg_records_7day,
    avg_time_7day,
    -- Anomaly flags
    CASE 
        WHEN records_processed > (avg_records_7day + 2 * stddev_records_7day) 
        THEN 'High Volume Anomaly'
        WHEN records_processed < (avg_records_7day - 2 * stddev_records_7day) 
        THEN 'Low Volume Anomaly'
        ELSE 'Normal'
    END as volume_anomaly_flag,
    CASE 
        WHEN processing_time_minutes > (avg_time_7day + 2 * stddev_time_7day) 
        THEN 'Slow Processing'
        ELSE 'Normal'
    END as performance_anomaly_flag,
    CASE 
        WHEN error_count > 5 THEN 'High Error Rate'
        WHEN error_count > 0 THEN 'Some Errors'
        ELSE 'No Errors'
    END as error_status,
    -- Overall health score
    CASE 
        WHEN error_count > 5 OR 
             records_processed > (avg_records_7day + 2 * COALESCE(stddev_records_7day, 0)) OR
             records_processed < (avg_records_7day - 2 * COALESCE(stddev_records_7day, 0)) OR
             processing_time_minutes > (avg_time_7day + 2 * COALESCE(stddev_time_7day, 0))
        THEN 'Unhealthy'
        ELSE 'Healthy'
    END as pipeline_health
FROM anomaly_detection
WHERE avg_records_7day IS NOT NULL  -- Exclude first 7 days where we don't have enough history
ORDER BY pipeline_name, run_date;
