-- =====================================================================
-- SLOWLY CHANGING DIMENSIONS (SCD) - TYPES 1, 2, AND 3 EXAMPLES
-- Comprehensive examples with datasets and implementation patterns
-- =====================================================================

-- =====================================================================
-- SETUP: INITIAL SOURCE DATA
-- =====================================================================

-- Source system data representing customer information changes over time
IF OBJECT_ID('source_customers', 'U') IS NOT NULL DROP TABLE source_customers;
CREATE TABLE source_customers (
    change_date DATE,
    customer_id INT,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(2),
    status VARCHAR(20),
    salary INT
);

INSERT INTO source_customers (change_date, customer_id, customer_name, email, phone, address, city, state, status, salary)
VALUES 
    -- Initial load - January 2023
    (CAST('2023-01-01' AS DATE), 1, 'John Smith', 'john@email.com', '555-1001', '123 Main St', 'New York', 'NY', 'Active', 50000),
    (CAST('2023-01-01' AS DATE), 2, 'Jane Doe', 'jane@email.com', '555-1002', '456 Oak Ave', 'Boston', 'MA', 'Active', 60000),
    (CAST('2023-01-01' AS DATE), 3, 'Bob Wilson', 'bob@email.com', '555-1003', '789 Pine St', 'Chicago', 'IL', 'Active', 55000),
    
    -- February 2023 - John changes phone and email
    (CAST('2023-02-15' AS DATE), 1, 'John Smith', 'john.smith@newemail.com', '555-9001', '123 Main St', 'New York', 'NY', 'Active', 50000),
    
    -- March 2023 - Jane gets promoted (salary increase) and moves
    (CAST('2023-03-10' AS DATE), 2, 'Jane Doe', 'jane@email.com', '555-1002', '789 Elm Street', 'Cambridge', 'MA', 'Active', 75000),
    
    -- April 2023 - Bob changes status to Inactive
    (CAST('2023-04-05' AS DATE), 3, 'Bob Wilson', 'bob@email.com', '555-1003', '789 Pine St', 'Chicago', 'IL', 'Inactive', 55000),
    
    -- May 2023 - John gets married (name change) and moves
    (CAST('2023-05-20' AS DATE), 1, 'John Johnson', 'john.johnson@newemail.com', '555-9001', '567 Broadway', 'Brooklyn', 'NY', 'Active', 52000),
    
    -- June 2023 - Jane changes phone
    (CAST('2023-06-12' AS DATE), 2, 'Jane Doe', 'jane@email.com', '555-8888', '789 Elm Street', 'Cambridge', 'MA', 'Active', 75000),
    
    -- July 2023 - New customer
    (CAST('2023-07-01' AS DATE), 4, 'Alice Brown', 'alice@email.com', '555-1004', '321 Cedar Ln', 'Seattle', 'WA', 'Active', 58000);

-- =====================================================================
-- SCD TYPE 1: OVERWRITE (KEEP ONLY CURRENT VALUES)
-- =====================================================================

-- Type 1: Simply overwrites old data with new data
-- Use when: You don't need to track historical changes
-- Examples: Correcting data errors, updating contact info that doesn't need history

IF OBJECT_ID('scd_type1_customer', 'U') IS NOT NULL DROP TABLE scd_type1_customer;
CREATE TABLE scd_type1_customer (
    customer_id INT,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(2),
    status VARCHAR(20),
    salary INT,
    last_updated DATETIME2
);

INSERT INTO scd_type1_customer (customer_id, customer_name, email, phone, address, city, state, status, salary, last_updated)
VALUES 
    (1, 'John Johnson', 'john.johnson@newemail.com', '555-9001', '567 Broadway', 'Brooklyn', 'NY', 'Active', 52000, GETDATE()),
    (2, 'Jane Doe', 'jane@email.com', '555-8888', '789 Elm Street', 'Cambridge', 'MA', 'Active', 75000, GETDATE()),
    (3, 'Bob Wilson', 'bob@email.com', '555-1003', '789 Pine St', 'Chicago', 'IL', 'Inactive', 55000, GETDATE()),
    (4, 'Alice Brown', 'alice@email.com', '555-1004', '321 Cedar Ln', 'Seattle', 'WA', 'Active', 58000, GETDATE());

-- SCD Type 1 Implementation Logic
WITH latest_source_data AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        phone,
        address,
        city,
        state,
        status,
        salary,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY change_date DESC) as rn
    FROM source_customers
)
SELECT 
    'SCD Type 1 - Current State Only' as description,
    customer_id,
    customer_name,
    email,
    phone,
    city,
    state,
    status,
    salary
FROM latest_source_data 
WHERE rn = 1
ORDER BY customer_id;

-- =====================================================================
-- SCD TYPE 2: KEEP FULL HISTORY WITH VERSIONING
-- =====================================================================

-- Type 2: Maintains complete historical record with effective dates
-- Use when: You need to track all historical changes for analysis
-- Examples: Tracking salary history, status changes, address moves

IF OBJECT_ID('scd_type2_customer', 'U') IS NOT NULL DROP TABLE scd_type2_customer;

WITH source_changes AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        phone,
        address,
        city,
        state,
        status,
        salary,
        change_date as effective_date
    FROM source_customers
),
scd2_logic AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY customer_id, effective_date) as surrogate_key,
        customer_id,
        customer_name,
        email,
        phone,
        address,
        city,
        state,
        status,
        salary,
        effective_date,
        -- Calculate end date (next change date or far future)
        COALESCE(
            DATEADD(day, -1, LEAD(effective_date) OVER (
                PARTITION BY customer_id 
                ORDER BY effective_date
            )), 
            CAST('9999-12-31' AS DATE)
        ) as end_date,
        -- Version number for each customer
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY effective_date
        ) as version_number,
        -- Current record flag
        CASE 
            WHEN LEAD(effective_date) OVER (
                PARTITION BY customer_id 
                ORDER BY effective_date
            ) IS NULL THEN 'Y'
            ELSE 'N'
        END as is_current,
        GETDATE() as created_date
    FROM source_changes
)
SELECT * 
INTO scd_type2_customer
FROM scd2_logic
ORDER BY customer_id, effective_date;


-- Query SCD Type 2: Show full history for customer 1 (John Smith/Johnson)
SELECT 
    'SCD Type 2 - Full History for Customer 1' as description,
    surrogate_key,
    customer_id,
    customer_name,
    email,
    phone,
    CONCAT(city, ', ', state) as location,
    salary,
    effective_date,
    end_date,
    version_number,
    is_current,
    DATEDIFF(day, effective_date, end_date) as days_active
FROM scd_type2_customer
WHERE customer_id = 1
ORDER BY effective_date;

-- Query SCD Type 2: Show only current records
SELECT 
    'SCD Type 2 - Current Records Only' as description,
    customer_id,
    customer_name,
    email,
    salary,
    effective_date,
    version_number
FROM scd_type2_customer
WHERE is_current = 'Y'
ORDER BY customer_id;

-- Query SCD Type 2: Point-in-time analysis (what data looked like on March 1, 2023)
SELECT 
    'SCD Type 2 - Point in Time: 2023-03-01' as description,
    customer_id,
    customer_name,
    email,
    salary,
    status,
    effective_date,
    end_date
FROM scd_type2_customer
WHERE CAST('2023-03-01' AS DATE) BETWEEN effective_date AND end_date
ORDER BY customer_id;

-- =====================================================================
-- SCD TYPE 3: KEEP CURRENT AND PREVIOUS VALUES
-- =====================================================================

-- Type 3: Stores both current and previous values in same record
-- Use when: You only need to track one level of history (current + previous)
-- Examples: Tracking previous address, previous salary, previous status

IF OBJECT_ID('scd_type3_customer', 'U') IS NOT NULL DROP TABLE scd_type3_customer;

select * from source_customers

WITH customer_history AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        phone,
        address,
        city,
        state,
        status,
        salary,
        change_date,
        LAG(address) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_address,
        LAG(city) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_city,
        LAG(state) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_state,
        LAG(salary) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_salary,
        LAG(status) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_status,
        LAG(change_date) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_change_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY change_date DESC) as rn
    FROM source_customers
)
SELECT 
    customer_id,
    customer_name,
    email,
    phone,
    -- Current values
    address as current_address,
    city as current_city,
    state as current_state,
    status as current_status,
    salary as current_salary,
    change_date as current_change_date,
    -- Previous values
    previous_address,
    previous_city,
    previous_state,
    previous_status,
    previous_salary,
    previous_change_date,
    -- Metadata
    GETDATE() as last_updated
INTO scd_type3_customer
FROM customer_history
WHERE rn = 1  -- Only keep the latest record for each customer
ORDER BY customer_id;

-- Query SCD Type 3: Show current vs previous comparison
SELECT 
    'SCD Type 3 - Current vs Previous Comparison' as description,
    customer_id,
    customer_name,
    current_address,
    previous_address,
    CASE 
        WHEN current_address != previous_address OR previous_address IS NULL 
        THEN 'Address Changed' 
        ELSE 'No Address Change' 
    END as address_change_flag,
    current_salary,
    previous_salary,
    current_salary - COALESCE(previous_salary, current_salary) as salary_change,
    current_status,
    previous_status,
    CASE 
        WHEN current_status != previous_status OR previous_status IS NULL 
        THEN 'Status Changed' 
        ELSE 'No Status Change' 
    END as status_change_flag
FROM scd_type3_customer
ORDER BY customer_id;

-- =====================================================================
-- COMPARISON: ALL THREE SCD TYPES FOR SAME DATA
-- =====================================================================

-- Side-by-side comparison showing how the same customer data is handled in each SCD type
SELECT 
    'SCD Comparison for Customer ID 1' as analysis_type,
    'Type 1 (Current Only)' as scd_type,
    1 as sort_order,
    customer_name,
    email,
    city,
    salary,
    NULL as effective_date,
    NULL as end_date,
    'N/A' as version_info
FROM scd_type1_customer 
WHERE customer_id = 1

UNION ALL

SELECT 
    'SCD Comparison for Customer ID 1',
    'Type 2 (Full History)',
    2,
    customer_name,
    email,
    city,
    salary,
    effective_date,
    end_date,
    'Version ' + CAST(version_number AS VARCHAR(10))
FROM scd_type2_customer 
WHERE customer_id = 1

UNION ALL

SELECT 
    'SCD Comparison for Customer ID 1',
    'Type 3 (Current + Previous)',
    3,
    customer_name,
    email,
    current_city,
    current_salary,
    current_change_date,
    NULL,
    'Current: ' + current_city + ' | Previous: ' + COALESCE(previous_city, 'None')
FROM scd_type3_customer 
WHERE customer_id = 1

ORDER BY sort_order, effective_date;

-- =====================================================================
-- ADVANCED SCD SCENARIOS AND BEST PRACTICES
-- =====================================================================

-- Scenario 1: Detecting changes between source and target (SCD Type 2)
WITH source_latest AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        phone,
        address,
        city,
        state,
        status,
        salary,
        change_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY change_date DESC) as rn
    FROM source_customers
),
current_scd2 AS (
    SELECT * FROM scd_type2_customer WHERE is_current = 'Y'
),
change_detection AS (
    SELECT 
        s.customer_id,
        s.customer_name,
        s.email,
        s.salary,
        s.status,
        t.salary as current_salary,
        t.status as current_status,
        CASE 
            WHEN t.customer_id IS NULL THEN 'NEW_CUSTOMER'
            WHEN s.customer_name != t.customer_name 
                OR s.email != t.email 
                OR s.phone != t.phone 
                OR s.address != t.address 
                OR s.city != t.city 
                OR s.state != t.state 
                OR s.status != t.status 
                OR s.salary != t.salary 
            THEN 'CHANGED'
            ELSE 'NO_CHANGE'
        END as change_type
    FROM source_latest s
    LEFT JOIN current_scd2 t ON s.customer_id = t.customer_id
    WHERE s.rn = 1
)
SELECT 
    'Change Detection Analysis' as analysis_type,
    change_type,
    COUNT(*) as record_count,
    STRING_AGG(CAST(customer_id AS VARCHAR(10)), ', ') as customer_ids
FROM change_detection
GROUP BY change_type
ORDER BY change_type;

-- Scenario 2: Business rules for different SCD types
SELECT 
    'SCD Type Selection Guidelines' as guideline_type,
    attribute_type,
    recommended_scd_type,
    reason,
    example
FROM VALUES 
    ('Contact Info', 'Email, Phone', 'Type 1', 'Usually corrections, no business value in history', 'Email typo fix'),
    ('Personal Info', 'Name, DOB', 'Type 1', 'Corrections or legal changes, overwrite', 'Marriage name change'),
    ('Location', 'Address, City, State', 'Type 2', 'Business analysis value in tracking moves', 'Customer relocation analysis'),
    ('Financial', 'Salary, Credit Score', 'Type 2', 'Critical for trend analysis and reporting', 'Salary progression tracking'),
    ('Status', 'Active/Inactive, Employment', 'Type 2', 'Important for lifecycle analysis', 'Customer status changes'),
    ('Categories', 'Customer Tier, Segment', 'Type 2 or Type 3', 'Business intelligence and segmentation', 'VIP status changes'),
    ('Preferences', 'Settings, Preferences', 'Type 3', 'Compare current vs previous behavior', 'Communication preferences')
as guidelines(attribute_type, recommended_scd_type, reason, example);

-- Scenario 3: Performance considerations for large SCD Type 2 tables
SELECT 
    'SCD Type 2 Performance Tips' as tip_category,
    optimization_area,
    recommendation,
    implementation_note
FROM VALUES 
    ('Indexing', 'Composite Index', 'CREATE INDEX ON (customer_id, effective_date)', 'Supports point-in-time queries'),
    ('Indexing', 'Current Flag Index', 'CREATE INDEX ON (is_current) WHERE is_current = ''Y''', 'Partial index for current records'),
    ('Partitioning', 'Date Partitioning', 'PARTITION BY RANGE (effective_date)', 'Archive old partitions'),
    ('Querying', 'Use Effective Dates', 'Always filter by date range', 'Avoid full table scans'),
    ('Maintenance', 'Archive Strategy', 'Move old records to archive tables', 'Keep active table smaller'),
    ('ETL', 'Incremental Processing', 'Process only changed records', 'Use change data capture (CDC)')
as performance_tips(optimization_area, recommendation, implementation_note);

-- =====================================================================
-- REAL-WORLD SCD IMPLEMENTATION PATTERNS
-- =====================================================================

-- Pattern 1: SCD Type 2 with surrogate keys and audit columns
IF OBJECT_ID('dim_customer_scd2_complete', 'U') IS NOT NULL DROP TABLE dim_customer_scd2_complete;

SELECT 
    -- Surrogate key (auto-incrementing)
    ROW_NUMBER() OVER (ORDER BY customer_id, effective_date) + 100000 as customer_sk,
    
    -- Business key
    customer_id as customer_bk,
    
    -- Attributes
    customer_name,
    email,
    phone,
    address,
    city,
    state,
    status,
    salary,
    
    -- SCD Type 2 metadata
    effective_date,
    COALESCE(
        DATEADD(day, -1, LEAD(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date)),
        CAST('9999-12-31' AS DATE)
    ) as expiration_date,
    CASE 
        WHEN LEAD(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date) IS NULL 
        THEN 'CURRENT'
        ELSE 'EXPIRED'
    END as record_status,
    
    -- Audit columns
    GETDATE() as created_date,
    SUSER_NAME() as created_by,
    'INITIAL_LOAD' as source_system,
    
    -- Version tracking
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY effective_date) as version_number
INTO dim_customer_scd2_complete   
FROM scd_type2_customer
ORDER BY customer_id, effective_date;

-- Pattern 2: Slowly Changing Dimension with Type 0 (No Change) attributes
IF OBJECT_ID('dim_customer_mixed_scd', 'U') IS NOT NULL DROP TABLE dim_customer_mixed_scd;

SELECT 
    customer_id,
    
    -- Type 0: Never changes (set once)
    customer_name as original_customer_name,
    MIN(change_date) OVER (PARTITION BY customer_id) as first_seen_date,
    
    -- Type 1: Always current (overwrite)
    email,
    phone,
    
    -- Type 2: Full history (versioned)
    address,
    city,
    state,
    salary,
    status,
    change_date as effective_date,
    
    -- Type 3: Current + Previous (limited history)
    LAG(salary) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_salary,
    LAG(status) OVER (PARTITION BY customer_id ORDER BY change_date) as previous_status
INTO dim_customer_mixed_scd
FROM source_customers
ORDER BY customer_id, change_date;

-- =====================================================================
-- SCD INTERVIEW QUESTIONS AND SOLUTIONS
-- =====================================================================

-- Question 1: Calculate customer lifetime value considering historical salary changes
WITH customer_tenure AS (
    SELECT 
        customer_id,
        customer_name,
        salary,
        effective_date,
        end_date,
        DATEDIFF(day, effective_date, 
            CASE WHEN end_date = CAST('9999-12-31' AS DATE) THEN CAST(GETDATE() AS DATE) ELSE end_date END
        ) as days_at_salary
    FROM scd_type2_customer
    WHERE status = 'Active'
),
lifetime_value AS (
    SELECT 
        customer_id,
        customer_name,
        COUNT(*) as salary_changes,
        SUM(salary * days_at_salary) / SUM(days_at_salary) as average_weighted_salary,
        MIN(salary) as min_salary,
        MAX(salary) as max_salary,
        SUM(days_at_salary) as total_active_days
    FROM customer_tenure
    GROUP BY customer_id, customer_name
)
SELECT 
    'Customer Lifetime Value Analysis' as analysis_type,
    customer_id,
    customer_name,
    salary_changes,
    ROUND(average_weighted_salary, 2) as avg_weighted_salary,
    min_salary,
    max_salary,
    total_active_days,
    ROUND((max_salary - min_salary) * 100.0 / min_salary, 2) as salary_growth_percentage
FROM lifetime_value
ORDER BY avg_weighted_salary DESC;

-- Question 2: Find customers who have moved states
WITH state_moves AS (
    SELECT 
        customer_id,
        customer_name,
        state,
        effective_date,
        LAG(state) OVER (PARTITION BY customer_id ORDER BY effective_date) as previous_state,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY effective_date) as state_version
    FROM scd_type2_customer
)
SELECT 
    'Customer State Movement Analysis' as analysis_type,
    customer_id,
    customer_name,
    previous_state + ' -> ' + state as state_move,
    effective_date as move_date,
    state_version
FROM state_moves
WHERE previous_state IS NOT NULL 
  AND previous_state != state
ORDER BY customer_id, effective_date;

-- Question 3: Identify rapid changes (multiple changes within 30 days)
WITH change_frequency AS (
    SELECT 
        customer_id,
        customer_name,
        effective_date,
        LAG(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date) as prev_change_date,
        DATEDIFF(day, 
            LAG(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date), 
            effective_date
        ) as days_between_changes
    FROM scd_type2_customer
)
SELECT 
    'Rapid Change Detection' as analysis_type,
    customer_id,
    customer_name,
    effective_date,
    prev_change_date,
    days_between_changes
FROM change_frequency
WHERE days_between_changes <= 30 
  AND days_between_changes > 0
ORDER BY days_between_changes, customer_id;

-- =====================================================================
-- SCD TYPE 4: HISTORY TABLE (MINI-DIMENSION)
-- =====================================================================

-- Type 4: Separate current and history tables
-- Use when: You need fast access to current data but also need to maintain history

-- Current table (fast access)
IF OBJECT_ID('scd_type4_customer_current', 'U') IS NOT NULL DROP TABLE scd_type4_customer_current;

WITH latest_customers AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        phone,
        address,
        city,
        state,
        status,
        salary,
        GETDATE() as last_updated,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY change_date DESC) as rn
    FROM source_customers
)
SELECT 
    customer_id,
    customer_name,
    email,
    phone,
    address,
    city,
    state,
    status,
    salary,
    last_updated
INTO scd_type4_customer_current
FROM latest_customers
WHERE rn = 1;

-- History table (all changes)
IF OBJECT_ID('scd_type4_customer_history', 'U') IS NOT NULL DROP TABLE scd_type4_customer_history;

SELECT 
    ROW_NUMBER() OVER (ORDER BY customer_id, change_date) as history_id,
    customer_id,
    customer_name,
    email,
    phone,
    address,
    city,
    state,
    status,
    salary,
    change_date,
    'HISTORICAL' as record_type,
    GETDATE() as created_date
INTO scd_type4_customer_history
FROM source_customers;

-- Query Type 4: Join current and history for comprehensive view
SELECT 
    'SCD Type 4 - Current with History Count' as description,
    c.customer_id,
    c.customer_name,
    c.email,
    c.salary as current_salary,
    c.status as current_status,
    COUNT(h.history_id) as total_changes,
    MIN(h.change_date) as first_change_date,
    MAX(h.change_date) as last_change_date
FROM scd_type4_customer_current c
LEFT JOIN scd_type4_customer_history h ON c.customer_id = h.customer_id
GROUP BY c.customer_id, c.customer_name, c.email, c.salary, c.status
ORDER BY c.customer_id;
