-- =========================================
-- Finding Duplicate Rows in SQL Server - Complete Guide
-- =========================================

-- This script works in any existing database
-- Uses unique table names to avoid conflicts with existing tables

-- Drop tables if they exist (for clean reruns)
IF OBJECT_ID('demo_customers_duplicates', 'U') IS NOT NULL
    DROP TABLE demo_customers_duplicates;
GO

IF OBJECT_ID('demo_customers_clean', 'U') IS NOT NULL
    DROP TABLE demo_customers_clean;
GO

-- Create a demo customers table with some duplicate records
CREATE TABLE demo_customers_duplicates (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    registration_date DATE
);
GO

-- Insert sample data including duplicates
INSERT INTO demo_customers_duplicates (first_name, last_name, email, phone, city, registration_date) VALUES
('John', 'Smith', 'john.smith@email.com', '555-1234', 'New York', '2024-01-15'),
('Jane', 'Doe', 'jane.doe@email.com', '555-5678', 'Los Angeles', '2024-01-16'),
('John', 'Smith', 'john.smith@email.com', '555-1234', 'New York', '2024-01-17'), -- Exact duplicate
('Mike', 'Johnson', 'mike.j@email.com', '555-9012', 'Chicago', '2024-01-18'),
('Sarah', 'Wilson', 'sarah.w@email.com', '555-3456', 'Houston', '2024-01-19'),
('John', 'Smith', 'john.smith2@email.com', '555-1234', 'New York', '2024-01-20'), -- Partial duplicate (same name, phone, city but different email)
('Jane', 'Doe', 'jane.doe@email.com', '555-7890', 'Los Angeles', '2024-01-21'), -- Partial duplicate (same name, email, city but different phone)
('Bob', 'Brown', 'bob.brown@email.com', '555-2468', 'Miami', '2024-01-22'),
('Alice', 'Davis', 'alice.davis@email.com', '555-1357', 'Seattle', '2024-01-23'),
('John', 'Smith', 'john.smith@email.com', '555-1234', 'New York', '2024-01-24'), -- Another exact duplicate
('Jon', 'Smyth', 'jon.smyth@email.com', '555-9999', 'New York', '2024-01-25'),
('Sara', 'Wylson', 'sara.wylson@email.com', '555-8888', 'Houston', '2024-01-26'),
('Myke', 'Jonson', 'myke.jonson2@email.com', '555-7777', 'Chicago', '2024-01-27');
GO


-- View the sample data
SELECT 'SAMPLE DATA:' as section;
SELECT * FROM demo_customers_duplicates ORDER BY first_name, last_name, email;
GO

-- =========================================
-- METHOD 1: Using GROUP BY and HAVING
-- =========================================
-- Most common and straightforward method to find duplicates

SELECT 'METHOD 1: GROUP BY and HAVING - Find exact duplicates' as method;
GO

-- Find exact duplicates based on all key columns (excluding ID and date)
SELECT 
    first_name,
    last_name,
    email,
    phone,
    city,
    COUNT(*) as duplicate_count
FROM demo_customers_duplicates
GROUP BY first_name, last_name, email, phone, city
HAVING COUNT(*) >= 1
ORDER BY duplicate_count DESC, first_name;
GO

-- Find duplicates based on specific columns (e.g., just name and email)
SELECT 'Find duplicates by name and email only:' as note;

SELECT 
    first_name,
    last_name,
    email,
    COUNT(*) as duplicate_count
FROM demo_customers_duplicates
GROUP BY first_name, last_name, email
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
GO

-- =========================================
-- METHOD 2: Using Window Functions (ROW_NUMBER)
-- =========================================
-- More flexible method that shows actual duplicate records with details

SELECT 'METHOD 2: ROW_NUMBER() - Show duplicate rows with details' as method;
GO

-- Find all duplicate rows with ROW_NUMBER
WITH DuplicateRows AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        city,
        registration_date,
        ROW_NUMBER() OVER (
            PARTITION BY first_name, last_name, email, phone, city 
            ORDER BY registration_date
        ) as row_num
    FROM demo_customers_duplicates
)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    city,
    registration_date,
    'Duplicate #' + CAST(row_num AS VARCHAR) as duplicate_order
FROM DuplicateRows
WHERE row_num > 1  -- Only show duplicates (keeps the first occurrence as original)
ORDER BY first_name, last_name, registration_date;
GO


SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    city,
    registration_date,
    ROW_NUMBER() OVER (
        -- PARTITION BY first_name, last_name, email, phone, city 
        ORDER BY registration_date
    ) as row_num
FROM demo_customers_duplicates

-- Show ALL occurrences of duplicated data (including the first one)
SELECT 'Show ALL occurrences of duplicated data:' as note;
GO

WITH DuplicateGroups AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        city,
        registration_date,
        COUNT(*) OVER (
            PARTITION BY first_name, last_name, email, phone, city
        ) as total_duplicates,
        ROW_NUMBER() OVER (
            PARTITION BY first_name, last_name, email, phone, city 
            ORDER BY registration_date
        ) as occurrence_number
    FROM demo_customers_duplicates
)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    city,
    registration_date,
    total_duplicates,
    'Occurrence ' + CAST(occurrence_number AS VARCHAR) + ' of ' + CAST(total_duplicates AS VARCHAR) as status
FROM DuplicateGroups
WHERE total_duplicates > 1  -- Only show records that have duplicates
ORDER BY first_name, last_name, registration_date;
GO

-- =========================================
-- METHOD 3: Using EXISTS
-- =========================================
-- Alternative approach using correlated subquery

SELECT 'METHOD 3: EXISTS - Using correlated subquery' as method;
GO

SELECT 
    c1.customer_id,
    c1.first_name,
    c1.last_name,
    c1.email,
    c1.phone,
    c1.city,
    c1.registration_date
FROM demo_customers_duplicates c1
WHERE EXISTS (
    SELECT 1 
    FROM demo_customers_duplicates c2 
    WHERE c2.first_name = c1.first_name
      AND c2.last_name = c1.last_name
      AND c2.email = c1.email
      AND c2.phone = c1.phone
      AND c2.city = c1.city
      AND c2.customer_id != c1.customer_id  -- Exclude the record itself
)
ORDER BY c1.first_name, c1.last_name, c1.registration_date;
GO

SELECT 1 
    FROM demo_customers_duplicates c2 


-- =========================================
-- METHOD 4: Using DENSE_RANK for Complex Scenarios
-- =========================================
-- Useful when you need to rank duplicates differently

SELECT 'METHOD 4: DENSE_RANK - Complex ranking scenarios' as method;
GO

WITH RankedDuplicates AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        city,
        registration_date,
        DENSE_RANK() OVER (
            PARTITION BY first_name, last_name, email 
            ORDER BY registration_date
        ) as duplicate_rank,
        COUNT(*) OVER (
            PARTITION BY first_name, last_name, email
        ) as group_size
    FROM demo_customers_duplicates
)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    city,
    registration_date,
    duplicate_rank,
    group_size,
    CASE 
        WHEN duplicate_rank = 1 THEN 'Original'
        ELSE 'Duplicate #' + CAST(duplicate_rank - 1 AS VARCHAR)
    END as record_status
FROM RankedDuplicates
WHERE group_size > 1
ORDER BY first_name, last_name, duplicate_rank;
GO

-- =========================================
-- PRACTICAL SCENARIOS
-- =========================================

SELECT 'PRACTICAL SCENARIOS' as section;
GO

-- Scenario 1: Find duplicate emails (common business requirement)
SELECT 'Scenario 1: Find duplicate emails' as scenario;
SELECT 
    email,
    COUNT(*) as email_count ,
    STRING_AGG(CAST(customer_id AS VARCHAR), ', ') as customer_ids
FROM demo_customers_duplicates
GROUP BY email
HAVING COUNT(*) > 1;
GO


-- Does not work when mixing withnon aggrgated column withh aggregated function
SELECT 
    -- email,
    -- COUNT(*) as email_count,
    STRING_AGG(CAST(customer_id AS VARCHAR), ', ') as customer_ids
FROM demo_customers_duplicates

-- works with group by
SELECT 
    email,
    STRING_AGG(CAST(customer_id AS VARCHAR), ', ') AS customer_ids
FROM demo_customers_duplicates
GROUP BY email;


-- Scenario 2: Find duplicate phone numbers
SELECT 'Scenario 2: Find duplicate phone numbers' as scenario;
SELECT 
    phone,
    COUNT(*) as phone_count,
    STRING_AGG(first_name + ' ' + last_name, ', ') as customers_with_phone
FROM demo_customers_duplicates
GROUP BY phone
HAVING COUNT(*) > 1;
GO

-- Scenario 3: Find potential duplicate persons (same name, different details)
SELECT 'Scenario 3: Find potential duplicate persons' as scenario;
SELECT 
    first_name,
    last_name,
    COUNT(*) as name_count,
    COUNT(DISTINCT email) as unique_emails,
    COUNT(DISTINCT phone) as unique_phones,
    STRING_AGG(email + ' ' + phone, '; ') as all_emails
FROM demo_customers_duplicates
GROUP BY first_name, last_name
HAVING COUNT(*) > 1
ORDER BY name_count DESC;
GO

-- =========================================
-- ADVANCED: Finding Near-Duplicates
-- =========================================
-- Using SOUNDEX for phonetically similar names

SELECT 'ADVANCED: Finding Near-Duplicates using SOUNDEX' as section;
GO

SELECT 
    c1.customer_id as id1,
    c1.first_name + ' ' + c1.last_name as name1,
    c1.email as email1,
    c2.customer_id as id2,
    c2.first_name + ' ' + c2.last_name as name2,
    c2.email as email2,
    'Phonetically Similar Names' as similarity_type
FROM demo_customers_duplicates c1
JOIN demo_customers_duplicates c2 ON 
    SOUNDEX(c1.first_name) = SOUNDEX(c2.first_name)
    AND SOUNDEX(c1.last_name) = SOUNDEX(c2.last_name)
    -- AND c1.customer_id < c2.customer_id  -- Avoid showing same pair twice
WHERE c1.first_name != c2.first_name OR c1.last_name != c2.last_name;
GO

-- =========================================
-- REMOVING DUPLICATES
-- =========================================

SELECT 'REMOVING DUPLICATES' as section;
GO

-- Show what would be deleted (without actually deleting)
SELECT 'Preview: Records that WOULD BE DELETED (keeping oldest)' as note;
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.registration_date,
    'WOULD BE DELETED' as action
FROM demo_customers_duplicates c
WHERE customer_id IN (
    SELECT customer_id 
    FROM (
        SELECT 
            customer_id,
            ROW_NUMBER() OVER (
                PARTITION BY first_name, last_name, email, phone, city 
                ORDER BY registration_date ASC
            ) as row_num
        FROM demo_customers_duplicates
    ) ranked
    WHERE row_num > 1
);
GO

-- Method 2: Create a new table without duplicates
SELECT 'Creating clean table without duplicates...' as note;
SELECT DISTINCT 
    first_name,
    last_name,
    email,
    phone,
    city,
    MIN(registration_date) as first_registration_date
INTO demo_customers_clean
FROM demo_customers_duplicates
GROUP BY first_name, last_name, email, phone, city;
GO

-- View the cleaned data
SELECT 'CLEANED DATA (demo_customers_clean table):' as section;
SELECT * FROM demo_customers_clean ORDER BY first_name, last_name;
GO

-- =========================================
-- SUMMARY
-- =========================================
/*
KEY METHODS SUMMARY:

1. GROUP BY + HAVING: Fast, simple duplicate counting
   - Best for: Quick duplicate identification
   - Performance: Excellent

2. ROW_NUMBER(): Flexible, shows actual duplicate records
   - Best for: Detailed analysis and duplicate removal
   - Performance: Good with proper indexes

3. EXISTS: Good for checking duplicate existence
   - Best for: Simple duplicate verification
   - Performance: Moderate

4. DENSE_RANK(): Complex ranking scenarios
   - Best for: Custom duplicate ranking logic
   - Performance: Moderate

PERFORMANCE TIPS:
- Create indexes on columns used for duplicate detection
- Use appropriate PARTITION BY columns in window functions
- Test DELETE operations on copies first
- Consider pagination for very large datasets

REAL-WORLD APPLICATION:
Replace "demo_customers_duplicates" with your actual table name
and modify the column names to match your schema.
*/

-- Cleanup (uncomment to remove demo tables)
-- DROP TABLE demo_customers_duplicates;
-- DROP TABLE demo_customers_clean;
