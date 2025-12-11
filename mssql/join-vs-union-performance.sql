/*
=====================================================
JOIN vs UNION Performance Comparison
=====================================================

This document provides a comprehensive comparison of JOIN and UNION operations
in terms of performance, use cases, and practical examples.

Table of Contents:
1. Understanding JOIN vs UNION
2. Performance Characteristics
3. Use Cases and When to Choose Each
4. Practical Examples
5. Performance Optimization Tips
6. Benchmark Examples
*/

-- =====================================================
-- 1. UNDERSTANDING JOIN vs UNION
-- =====================================================

/*
JOIN: Combines columns from multiple tables based on a related column
UNION: Combines rows from multiple tables with similar structure

Key Differences:
- JOIN: Horizontal combination (adding columns)
- UNION: Vertical combination (adding rows)
- JOIN: Can result in cartesian products if not properly filtered
- UNION: Automatically removes duplicates (UNION ALL keeps duplicates)
*/

-- =====================================================
-- 2. SAMPLE DATA SETUP
-- =====================================================

-- Create sample tables for demonstration
CREATE TABLE #Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    region VARCHAR(20),
    registration_date DATE
);

CREATE TABLE #Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    amount DECIMAL(10,2)
);

CREATE TABLE #CustomerHistory (
    customer_id INT,
    customer_name VARCHAR(50),
    region VARCHAR(20),
    registration_date DATE,
    source_system VARCHAR(20)
);

-- Insert sample data
INSERT INTO #Customers VALUES 
(1, 'John Doe', 'North', '2023-01-15'),
(2, 'Jane Smith', 'South', '2023-02-20'),
(3, 'Bob Johnson', 'East', '2023-03-10'),
(4, 'Alice Brown', 'West', '2023-01-05'),
(5, 'Charlie Davis', 'North', '2023-04-12');

INSERT INTO #Orders VALUES
(101, 1, '2023-06-01', 250.00),
(102, 1, '2023-06-15', 175.50),
(103, 2, '2023-06-05', 320.75),
(104, 3, '2023-06-10', 89.99),
(105, 2, '2023-06-20', 445.25),
(106, 4, '2023-06-08', 167.80),
(107, 1, '2023-06-25', 298.40);

INSERT INTO #CustomerHistory VALUES
(1, 'John Doe', 'North', '2023-01-15', 'Legacy_System'),
(2, 'Jane Smith', 'South', '2023-02-20', 'Legacy_System'),
(6, 'Diana Prince', 'Central', '2022-12-01', 'Legacy_System'),
(7, 'Bruce Wayne', 'East', '2022-11-15', 'Legacy_System'),
(8, 'Clark Kent', 'West', '2022-10-30', 'Legacy_System');

-- =====================================================
-- 3. JOIN EXAMPLES AND USE CASES
-- =====================================================

/*
JOIN Use Cases:
- Combining related data from multiple tables
- Creating comprehensive reports with data from different entities
- Analyzing relationships between entities
- Data enrichment from multiple sources
*/

-- Example 1: Simple JOIN - Customer Orders Report
SELECT 
    c.customer_name,
    c.region,
    o.order_date,
    o.amount,
    ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) as order_sequence
FROM #Customers c
INNER JOIN #Orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_name, o.order_date;

-- Example 2: JOIN with Aggregation - Customer Summary
SELECT 
    c.customer_name,
    c.region,
    COUNT(o.order_id) as total_orders,
    SUM(o.amount) as total_spent,
    AVG(o.amount) as avg_order_value,
    MAX(o.order_date) as last_order_date
FROM #Customers c
LEFT JOIN #Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.region
ORDER BY total_spent DESC;

-- Example 3: Complex JOIN - Regional Analysis
SELECT 
    c.region,
    COUNT(DISTINCT c.customer_id) as customers_count,
    COUNT(o.order_id) as total_orders,
    SUM(o.amount) as total_revenue,
    AVG(o.amount) as avg_order_value,
    SUM(o.amount) / COUNT(DISTINCT c.customer_id) as revenue_per_customer
FROM #Customers c
LEFT JOIN #Orders o ON c.customer_id = o.customer_id
GROUP BY c.region
ORDER BY total_revenue DESC;

-- =====================================================
-- 4. UNION, INTERSECT, AND EXCEPT EXAMPLES
-- =====================================================

/*
Set Operations in SQL:
UNION - Combines rows from multiple tables (vertical combination)
INTERSECT - Returns common rows between two result sets
EXCEPT - Returns rows from first set that don't exist in second set (like MINUS in Oracle)

UNION Use Cases:
- Combining data from multiple sources with similar structure
- Historical data consolidation
- Creating comprehensive datasets from partitioned tables
- Data migration scenarios

INTERSECT Use Cases:
- Finding exact matches between datasets
- Data validation and comparison
- Identifying common records across systems

EXCEPT Use Cases:
- Finding missing records
- Data difference analysis
- Migration validation
*/

-- =====================================================
-- 4.1. UNION EXAMPLES
-- =====================================================

-- Example 1: Simple UNION - Combining Current and Historical Customers
SELECT 
    customer_id,
    customer_name,
    region,
    registration_date,
    'Current_System' as source_system
FROM #Customers
UNION
SELECT 
    customer_id,
    customer_name,
    region,
    registration_date,
    source_system
FROM #CustomerHistory
ORDER BY registration_date DESC;

-- Example 2: UNION ALL vs UNION - Performance Difference
-- UNION (removes duplicates - slower)
SELECT 
    customer_name,
    region
FROM #Customers
UNION
SELECT 
    customer_name,
    region
FROM #CustomerHistory;

-- UNION ALL (keeps duplicates - faster)
SELECT 
    customer_name,
    region
FROM #Customers
UNION ALL
SELECT 
    customer_name,
    region
FROM #CustomerHistory;

-- Example 3: Complex UNION - Monthly Sales Summary from Multiple Sources
-- Simulating data from different monthly tables
WITH Jan_Sales AS (
    SELECT 'January' as month, SUM(amount) as monthly_total, COUNT(*) as order_count
    FROM #Orders WHERE MONTH(order_date) = 6  -- Using June data as example
),
Feb_Sales AS (
    SELECT 'February' as month, SUM(amount) * 0.8 as monthly_total, COUNT(*) - 1 as order_count
    FROM #Orders WHERE MONTH(order_date) = 6
),
Mar_Sales AS (
    SELECT 'March' as month, SUM(amount) * 1.2 as monthly_total, COUNT(*) + 2 as order_count
    FROM #Orders WHERE MONTH(order_date) = 6
)
SELECT * FROM Jan_Sales
UNION ALL
SELECT * FROM Feb_Sales
UNION ALL
SELECT * FROM Mar_Sales;

-- =====================================================
-- 5. PERFORMANCE CHARACTERISTICS
-- =====================================================

/*
JOIN Performance Factors:
✓ Pros:
- Single query execution
- Can leverage indexes effectively
- Memory efficient for large datasets
- Optimal for relational data

✗ Cons:
- Can create cartesian products if not careful
- Complex joins can be CPU intensive
- May require careful indexing strategy

UNION Performance Factors:
✓ Pros:
- Simple operation for combining similar datasets
- UNION ALL is very fast
- Good for data consolidation

✗ Cons:
- UNION (with duplicate removal) is slower than UNION ALL
- Requires compatible column structures
- May require multiple table scans
*/

-- Performance Test Example - Compare execution plans
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- JOIN Query
SELECT COUNT(*)
FROM #Customers c
INNER JOIN #Orders o ON c.customer_id = o.customer_id;

-- UNION Query (not directly comparable, but shows different operation)
SELECT COUNT(*)
FROM (
    SELECT customer_id FROM #Customers
    UNION ALL
    SELECT customer_id FROM #CustomerHistory
) combined;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- =====================================================
-- 6. WHEN TO USE WHICH OPERATION
-- =====================================================

/*
Use JOIN when:
- You need to combine related data from multiple tables
- You're creating reports that need columns from different entities
- You're analyzing relationships between entities
- You need to enrich data with additional attributes
- You're working with normalized database structures

Use UNION when:
- You need to combine rows from tables with similar structure
- You're consolidating data from multiple sources
- You're working with historical/archived data
- You're migrating data from multiple systems
- You need to create a unified view of partitioned data

Performance Guidelines:
1. Use UNION ALL instead of UNION when duplicates are acceptable
2. Ensure proper indexes for JOIN operations
3. Consider the size of datasets - JOINs can be more memory efficient
4. Use appropriate WHERE clauses to filter data early
5. Consider partitioning strategies for large UNION operations
*/

-- =====================================================
-- 7. REAL-WORLD SCENARIOS
-- =====================================================

-- Scenario 1: E-commerce Platform
-- JOIN for Order Analysis
SELECT 
    c.customer_name,
    c.region,
    COUNT(o.order_id) as orders_this_month,
    SUM(o.amount) as revenue_this_month
FROM #Customers c
LEFT JOIN #Orders o ON c.customer_id = o.customer_id 
    AND o.order_date >= '2023-06-01'
GROUP BY c.customer_id, c.customer_name, c.region;

-- UNION for Customer Master Data
SELECT 
    customer_id,
    customer_name,
    region,
    registration_date,
    'Active' as status
FROM #Customers
UNION ALL
SELECT 
    customer_id,
    customer_name,
    region,
    registration_date,
    'Historical' as status
FROM #CustomerHistory;

-- Scenario 2: Data Warehouse ETL
-- UNION for combining multiple data sources
WITH CombinedCustomers AS (
    SELECT customer_id, customer_name, region, 'Production' as source 
    FROM #Customers
    UNION ALL
    SELECT customer_id, customer_name, region, 'Archive' as source 
    FROM #CustomerHistory
)
SELECT 
    region,
    source,
    COUNT(*) as customer_count
FROM CombinedCustomers
GROUP BY region, source
ORDER BY region, source;

-- =====================================================
-- 8. OPTIMIZATION TIPS
-- =====================================================

/*
JOIN Optimization:
1. Create appropriate indexes on join columns
2. Use INNER JOIN when possible instead of LEFT/RIGHT JOIN
3. Filter early with WHERE clauses
4. Consider join order in complex queries
5. Use EXISTS instead of IN for subqueries when appropriate

UNION Optimization:
1. Use UNION ALL when duplicates don't matter
2. Ensure all SELECT statements have similar performance
3. Consider using indexes on ORDER BY columns after UNION
4. Filter data before UNION operations when possible
5. Consider partitioning for very large datasets
*/

-- Example of optimized queries
-- Optimized JOIN with proper filtering
SELECT 
    c.customer_name,
    SUM(o.amount) as total_spent
FROM #Customers c
INNER JOIN #Orders o ON c.customer_id = o.customer_id
WHERE c.region IN ('North', 'South')
    AND o.order_date >= '2023-06-01'
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.amount) > 200;

-- Optimized UNION with pre-filtering
SELECT customer_name, region FROM #Customers WHERE region = 'North'
UNION ALL
SELECT customer_name, region FROM #CustomerHistory WHERE region = 'North';

-- =====================================================
-- 9. HANDLING COMMON UNION CHALLENGES
-- =====================================================

/*
Common UNION Issues and Solutions:
1. Column count mismatch
2. Data type mismatches
3. NULL handling
4. Column name differences
5. Different column orders
*/

-- Create tables with different structures for demonstration
CREATE TABLE #Products_Current (
    product_id INT,
    product_name VARCHAR(50),
    category VARCHAR(30),
    price DECIMAL(10,2),
    launch_date DATE,
    is_active BIT
);

CREATE TABLE #Products_Legacy (
    id INT,
    name VARCHAR(100),  -- Different length
    category_code CHAR(5),  -- Different data type
    cost MONEY,  -- Different data type
    created_at DATETIME,  -- Different data type
    status VARCHAR(10)  -- Different data type
);

CREATE TABLE #Products_Incomplete (
    product_id INT,
    product_name VARCHAR(50),
    price DECIMAL(10,2)
    -- Missing columns: category, launch_date, is_active
);

-- Insert sample data
INSERT INTO #Products_Current VALUES
(1, 'Laptop Pro', 'Electronics', 1299.99, '2023-01-15', 1),
(2, 'Wireless Mouse', 'Accessories', 29.99, '2023-02-10', 1),
(3, 'USB Cable', 'Accessories', 9.99, '2023-01-20', 0);

INSERT INTO #Products_Legacy VALUES
(100, 'Desktop Computer', 'COMP', 899.50, '2022-12-01 10:30:00', 'Active'),
(101, 'Keyboard Mechanical', 'ACC', 89.95, '2022-11-15 14:20:00', 'Inactive'),
(102, 'Monitor 4K', 'DISP', 349.99, '2022-10-30 09:15:00', 'Active');

INSERT INTO #Products_Incomplete VALUES
(200, 'Tablet Mini', 299.99),
(201, 'Phone Case', 19.99),
(202, 'Screen Protector', 12.50);

-- =====================================================
-- PROBLEM 1: Column Count Mismatch
-- =====================================================

-- This will FAIL - different number of columns
/*
SELECT product_id, product_name, price 
FROM #Products_Current
UNION ALL
SELECT product_id, product_name, category, price  -- Extra column!
FROM #Products_Incomplete;
*/

-- SOLUTION: Add placeholder columns or select matching columns
SELECT 
    product_id, 
    product_name, 
    price,
    'Current' as source,
    CAST(NULL AS VARCHAR(30)) as missing_info
FROM #Products_Current
UNION ALL
SELECT 
    product_id, 
    product_name, 
    price,
    'Incomplete' as source,
    'Missing category data' as missing_info
FROM #Products_Incomplete;

-- =====================================================
-- PROBLEM 2: Data Type Mismatch
-- =====================================================

-- This will FAIL - different data types
/*
SELECT product_id, product_name, category, price
FROM #Products_Current
UNION ALL
SELECT id, name, category_code, cost  -- Different types!
FROM #Products_Legacy;
*/

-- SOLUTION: Use CAST/CONVERT to standardize data types
SELECT 
    product_id,
    product_name,
    category,
    price,
    'Current' as source_system
FROM #Products_Current
UNION ALL
SELECT 
    id as product_id,
    CAST(name AS VARCHAR(50)) as product_name,  -- Truncate longer VARCHAR
    CAST(category_code AS VARCHAR(30)) as category,  -- Convert CHAR to VARCHAR
    CAST(cost AS DECIMAL(10,2)) as price,  -- Convert MONEY to DECIMAL
    'Legacy' as source_system
FROM #Products_Legacy;

-- =====================================================
-- PROBLEM 3: NULL Handling and Missing Columns
-- =====================================================

-- SOLUTION: Use NULL placeholders for missing columns
SELECT 
    product_id,
    product_name,
    category,
    price,
    launch_date,
    is_active,
    'Complete Data' as data_quality
FROM #Products_Current
UNION ALL
SELECT 
    id as product_id,
    CAST(name AS VARCHAR(50)) as product_name,
    CAST(category_code AS VARCHAR(30)) as category,
    CAST(cost AS DECIMAL(10,2)) as price,
    CAST(created_at AS DATE) as launch_date,  -- Convert DATETIME to DATE
    CASE WHEN status = 'Active' THEN 1 ELSE 0 END as is_active,  -- Convert VARCHAR to BIT
    'Legacy Data' as data_quality
FROM #Products_Legacy
UNION ALL
SELECT 
    product_id,
    product_name,
    NULL as category,  -- Missing column - use NULL
    price,
    NULL as launch_date,  -- Missing column - use NULL
    NULL as is_active,  -- Missing column - use NULL
    'Incomplete Data' as data_quality
FROM #Products_Incomplete;

-- =====================================================
-- PROBLEM 4: Different Column Names and Order
-- =====================================================

-- SOLUTION: Explicitly map columns and use aliases
WITH StandardizedProducts AS (
    -- Current products with standard column names
    SELECT 
        product_id as id,
        product_name as name,
        category,
        price as cost,
        launch_date as date_created,
        CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END as status,
        'Current' as source
    FROM #Products_Current
    
    UNION ALL
    
    -- Legacy products mapped to standard structure
    SELECT 
        id,
        CAST(name AS VARCHAR(50)) as name,
        CAST(category_code AS VARCHAR(30)) as category,
        CAST(cost AS DECIMAL(10,2)) as cost,
        CAST(created_at AS DATE) as date_created,
        status,
        'Legacy' as source
    FROM #Products_Legacy
    
    UNION ALL
    
    -- Incomplete products with NULLs for missing data
    SELECT 
        product_id as id,
        product_name as name,
        'Unknown' as category,  -- Default value instead of NULL
        price as cost,
        '1900-01-01' as date_created,  -- Default date instead of NULL
        'Unknown' as status,
        'Incomplete' as source
    FROM #Products_Incomplete
)
SELECT * FROM StandardizedProducts
ORDER BY source, id;

-- =====================================================
-- ADVANCED UNION TRICKS AND TECHNIQUES
-- =====================================================

-- Trick 1: Using COALESCE for NULL handling
SELECT 
    product_id,
    COALESCE(product_name, 'Unknown Product') as product_name,
    COALESCE(category, 'Uncategorized') as category,
    price
FROM #Products_Current
UNION ALL
SELECT 
    product_id,
    COALESCE(product_name, 'Unknown Product') as product_name,
    COALESCE(NULL, 'Uncategorized') as category,  -- Will use default
    price
FROM #Products_Incomplete;

-- Trick 2: Using ISNULL for SQL Server specific NULL handling
SELECT 
    product_id,
    ISNULL(product_name, 'No Name') as product_name,
    ISNULL(category, 'No Category') as category
FROM #Products_Current
UNION ALL
SELECT 
    product_id,
    ISNULL(product_name, 'No Name') as product_name,
    ISNULL(NULL, 'No Category') as category
FROM #Products_Incomplete;

-- Trick 3: Data type standardization with error handling
SELECT 
    product_id,
    product_name,
    TRY_CAST(price AS VARCHAR(20)) as price_text,  -- Safe conversion
    TRY_CAST(launch_date AS VARCHAR(10)) as date_text
FROM #Products_Current
UNION ALL
SELECT 
    id as product_id,
    name as product_name,
    TRY_CAST(cost AS VARCHAR(20)) as price_text,
    TRY_CAST(created_at AS VARCHAR(10)) as date_text
FROM #Products_Legacy;

-- Trick 4: Conditional logic for complex transformations
SELECT 
    product_id,
    product_name,
    category,
    CASE 
        WHEN price > 1000 THEN 'Premium'
        WHEN price > 100 THEN 'Standard'
        ELSE 'Budget'
    END as price_category,
    'Current' as source
FROM #Products_Current
UNION ALL
SELECT 
    id as product_id,
    CAST(name AS VARCHAR(50)) as product_name,
    CASE 
        WHEN category_code = 'COMP' THEN 'Electronics'
        WHEN category_code = 'ACC' THEN 'Accessories'
        WHEN category_code = 'DISP' THEN 'Displays'
        ELSE 'Other'
    END as category,
    CASE 
        WHEN cost > 1000 THEN 'Premium'
        WHEN cost > 100 THEN 'Standard'
        ELSE 'Budget'
    END as price_category,
    'Legacy' as source
FROM #Products_Legacy;

-- =====================================================
-- PERFORMANCE IMPACT OF DATA TYPE CONVERSIONS
-- =====================================================

-- Performance comparison: Direct UNION vs UNION with conversions
SET STATISTICS TIME ON;

-- Fast UNION ALL - no conversions needed
SELECT product_id, product_name FROM #Products_Current
UNION ALL
SELECT product_id, product_name FROM #Products_Incomplete;

-- Slower UNION ALL - with data type conversions
SELECT 
    CAST(product_id AS BIGINT) as product_id,
    CAST(product_name AS NVARCHAR(100)) as product_name
FROM #Products_Current
UNION ALL
SELECT 
    CAST(id AS BIGINT) as product_id,
    CAST(name AS NVARCHAR(100)) as product_name
FROM #Products_Legacy;

SET STATISTICS TIME OFF;

-- =====================================================
-- BEST PRACTICES FOR UNION OPERATIONS
-- =====================================================

/*
Best Practices:
1. Always ensure column count and order match
2. Use explicit CAST/CONVERT for data type mismatches
3. Handle NULLs consistently across all queries
4. Use meaningful default values instead of NULL when appropriate
5. Consider performance impact of data type conversions
6. Test with actual data sizes to measure performance
7. Use UNION ALL when duplicates are acceptable (faster)
8. Consider using ISNULL/COALESCE for default values
9. Document any data transformations in comments
10. Use CTEs to make complex UNION operations more readable
*/

-- Example of well-structured UNION with all best practices
WITH CleanedCurrentProducts AS (
    SELECT 
        CAST(product_id AS INT) as product_id,
        CAST(ISNULL(product_name, 'Unknown') AS VARCHAR(100)) as product_name,
        CAST(ISNULL(category, 'Uncategorized') AS VARCHAR(50)) as category,
        CAST(ISNULL(price, 0) AS DECIMAL(12,2)) as price,
        CAST(ISNULL(launch_date, '1900-01-01') AS DATE) as launch_date,
        CAST(ISNULL(is_active, 0) AS BIT) as is_active,
        'CURRENT' as source_system,
        GETDATE() as processed_date
    FROM #Products_Current
),
CleanedLegacyProducts AS (
    SELECT 
        CAST(id AS INT) as product_id,
        CAST(ISNULL(name, 'Unknown') AS VARCHAR(100)) as product_name,
        CAST(
            CASE 
                WHEN category_code = 'COMP' THEN 'Electronics'
                WHEN category_code = 'ACC' THEN 'Accessories'
                WHEN category_code = 'DISP' THEN 'Displays'
                ELSE 'Other'
            END AS VARCHAR(50)
        ) as category,
        CAST(ISNULL(cost, 0) AS DECIMAL(12,2)) as price,
        CAST(ISNULL(created_at, '1900-01-01') AS DATE) as launch_date,
        CAST(CASE WHEN status = 'Active' THEN 1 ELSE 0 END AS BIT) as is_active,
        'LEGACY' as source_system,
        GETDATE() as processed_date
    FROM #Products_Legacy
),
CleanedIncompleteProducts AS (
    SELECT 
        CAST(product_id AS INT) as product_id,
        CAST(ISNULL(product_name, 'Unknown') AS VARCHAR(100)) as product_name,
        CAST('Incomplete Data' AS VARCHAR(50)) as category,
        CAST(ISNULL(price, 0) AS DECIMAL(12,2)) as price,
        CAST('1900-01-01' AS DATE) as launch_date,
        CAST(0 AS BIT) as is_active,
        'INCOMPLETE' as source_system,
        GETDATE() as processed_date
    FROM #Products_Incomplete
)
-- Final UNION with all cleaned data
SELECT * FROM CleanedCurrentProducts
UNION ALL
SELECT * FROM CleanedLegacyProducts  
UNION ALL
SELECT * FROM CleanedIncompleteProducts
ORDER BY source_system, product_id;

-- =====================================================
-- CLEANUP
-- =====================================================
DROP TABLE #Products_Current;
DROP TABLE #Products_Legacy;
DROP TABLE #Products_Incomplete;
DROP TABLE #Customers;
DROP TABLE #Orders;
DROP TABLE #CustomerHistory;


Performance Comparison:
- JOIN: Best for relational operations, single query execution, memory efficient
- UNION: Best for data consolidation, simple operations, multiple source combining

Choose JOIN when:
- Combining related entities
- Need columns from multiple tables
- Working with normalized data
- Need complex filtering and aggregation

Choose UNION when:
- Combining similar datasets
- Data consolidation from multiple sources
- Historical data integration
- Simple row combination

Key Performance Tips:
- Use UNION ALL instead of UNION when possible
- Properly index JOIN columns
- Filter data early in both operations
- Consider query execution plans for optimization
*/
-- =====================================================
-- 10. INTERSECT AND EXCEPT OPERATIONS
-- =====================================================

/*
INTERSECT: Returns common rows between two result sets (like INNER JOIN but for entire rows)
EXCEPT: Returns rows from first result set that don't exist in second (like LEFT JOIN with IS NULL)

Both operations:
- Remove duplicates automatically (like UNION, not UNION ALL)
- Compare entire row values
- Are set operations like UNION
- Handle NULLs specially in comparisons
*/

-- Create additional sample data for INTERSECT/EXCEPT demonstrations
CREATE TABLE #Customers_Current (
    customer_id INT,
    customer_name VARCHAR(50),
    region VARCHAR(20),
    status VARCHAR(10)
);

CREATE TABLE #Customers_Archive (
    customer_id INT,
    customer_name VARCHAR(50),
    region VARCHAR(20),
    status VARCHAR(10)
);

-- Insert data with overlaps, duplicates, and NULLs
INSERT INTO #Customers_Current VALUES
(1, 'John Doe', 'North', 'Active'),
(2, 'Jane Smith', 'South', 'Active'),
(3, 'Bob Johnson', 'East', 'Inactive'),
(4, 'Alice Brown', NULL, 'Active'),  -- NULL region
(5, 'Charlie Davis', 'North', 'Active'),
(6, 'Diana Prince', 'Central', NULL),  -- NULL status
(2, 'Jane Smith', 'South', 'Active'),  -- Duplicate row
(7, 'Bruce Wayne', 'East', 'Active');

INSERT INTO #Customers_Archive VALUES
(1, 'John Doe', 'North', 'Active'),  -- Exact match with current
(2, 'Jane Smith', 'South', 'Inactive'),  -- Same person, different status
(8, 'Clark Kent', 'West', 'Active'),  -- Only in archive
(9, 'Peter Parker', 'North', 'Active'),
(4, 'Alice Brown', NULL, 'Active'),  -- NULL match
(10, 'Tony Stark', 'Central', NULL),  -- Different NULL pattern
(8, 'Clark Kent', 'West', 'Active');  -- Duplicate in archive

-- =====================================================
-- INTERSECT EXAMPLES
-- =====================================================

-- Example 1: Basic INTERSECT - Find exact matches between tables
SELECT customer_id, customer_name, region, status
FROM #Customers_Current
INTERSECT
SELECT customer_id, customer_name, region, status
FROM #Customers_Archive;

-- Example 2: INTERSECT with specific columns - Find customers with same ID and name
SELECT customer_id, customer_name
FROM #Customers_Current
INTERSECT
SELECT customer_id, customer_name
FROM #Customers_Archive;

-- Example 3: INTERSECT vs INNER JOIN comparison
-- INTERSECT (removes duplicates, compares entire rows)
SELECT customer_id, customer_name, region
FROM #Customers_Current
INTERSECT
SELECT customer_id, customer_name, region
FROM #Customers_Archive;

-- Equivalent INNER JOIN (may include duplicates, more flexible)
SELECT DISTINCT c1.customer_id, c1.customer_name, c1.region
FROM #Customers_Current c1
INNER JOIN #Customers_Archive c2 
    ON c1.customer_id = c2.customer_id 
    AND c1.customer_name = c2.customer_name 
    AND ISNULL(c1.region, '') = ISNULL(c2.region, '');

-- =====================================================
-- EXCEPT EXAMPLES
-- =====================================================

-- Example 1: Basic EXCEPT - Find customers only in current system
SELECT customer_id, customer_name, region, status
FROM #Customers_Current
EXCEPT
SELECT customer_id, customer_name, region, status
FROM #Customers_Archive;

-- Example 2: EXCEPT - Find archived customers not in current system
SELECT customer_id, customer_name, region, status
FROM #Customers_Archive
EXCEPT
SELECT customer_id, customer_name, region, status
FROM #Customers_Current;

-- Example 3: EXCEPT vs LEFT JOIN comparison
-- EXCEPT (removes duplicates, compares entire rows)
SELECT customer_id, customer_name
FROM #Customers_Current
EXCEPT
SELECT customer_id, customer_name
FROM #Customers_Archive;

-- Equivalent LEFT JOIN (may include duplicates, more flexible)
SELECT DISTINCT c1.customer_id, c1.customer_name
FROM #Customers_Current c1
LEFT JOIN #Customers_Archive c2 
    ON c1.customer_id = c2.customer_id 
    AND c1.customer_name = c2.customer_name
WHERE c2.customer_id IS NULL;

-- =====================================================
-- NULL HANDLING IN INTERSECT/EXCEPT
-- =====================================================

-- Create tables specifically for NULL handling demonstration
CREATE TABLE #Table_A (
    id INT,
    name VARCHAR(50),
    value VARCHAR(20)
);

CREATE TABLE #Table_B (
    id INT,
    name VARCHAR(50),
    value VARCHAR(20)
);

-- Insert data with various NULL patterns
INSERT INTO #Table_A VALUES
(1, 'Record 1', 'Value A'),
(2, 'Record 2', NULL),
(3, NULL, 'Value C'),
(4, NULL, NULL),
(5, 'Record 5', 'Value E');

INSERT INTO #Table_B VALUES
(1, 'Record 1', 'Value A'),  -- Exact match
(2, 'Record 2', NULL),       -- NULL matches NULL
(3, NULL, 'Value C'),        -- NULL matches NULL
(4, NULL, NULL),             -- Both NULLs match
(6, 'Record 6', 'Value F');  -- Different record

-- INTERSECT with NULLs - NULLs are considered equal
SELECT id, name, value
FROM #Table_A
INTERSECT
SELECT id, name, value
FROM #Table_B;

-- EXCEPT with NULLs
SELECT id, name, value
FROM #Table_A
EXCEPT
SELECT id, name, value
FROM #Table_B;

-- Comparison: How JOIN handles NULLs differently
SELECT DISTINCT a.id, a.name, a.value
FROM #Table_A a
INNER JOIN #Table_B b 
    ON a.id = b.id 
    AND ISNULL(a.name, '') = ISNULL(b.name, '')
    AND ISNULL(a.value, '') = ISNULL(b.value, '');

-- =====================================================
-- DUPLICATE HANDLING IN INTERSECT/EXCEPT
-- =====================================================

-- Create tables with duplicates
CREATE TABLE #Sales_Team_A (
    employee_id INT,
    employee_name VARCHAR(50),
    region VARCHAR(20)
);

CREATE TABLE #Sales_Team_B (
    employee_id INT,
    employee_name VARCHAR(50),
    region VARCHAR(20)
);

-- Insert data with duplicates
INSERT INTO #Sales_Team_A VALUES
(1, 'John Smith', 'North'),
(1, 'John Smith', 'North'),  -- Duplicate
(2, 'Jane Doe', 'South'),
(3, 'Bob Wilson', 'East'),
(3, 'Bob Wilson', 'East'),   -- Duplicate
(4, 'Alice Johnson', 'West');

INSERT INTO #Sales_Team_B VALUES
(1, 'John Smith', 'North'),
(2, 'Jane Doe', 'South'),
(2, 'Jane Doe', 'South'),    -- Duplicate
(5, 'Charlie Brown', 'Central'),
(6, 'Diana Prince', 'North'),
(6, 'Diana Prince', 'North'); -- Duplicate

-- INTERSECT automatically removes duplicates
SELECT employee_id, employee_name, region
FROM #Sales_Team_A
INTERSECT
SELECT employee_id, employee_name, region
FROM #Sales_Team_B;

-- Show original data has duplicates
SELECT 'Team A' as team, employee_id, employee_name, region FROM #Sales_Team_A
UNION ALL
SELECT 'Team B' as team, employee_id, employee_name, region FROM #Sales_Team_B
ORDER BY team, employee_id;

-- Count duplicates in each table
SELECT 'Team A Duplicates' as info, 
    COUNT(*) as total_rows, 
    COUNT(DISTINCT CONCAT(employee_id, employee_name, region)) as unique_rows
FROM #Sales_Team_A
UNION ALL
SELECT 'Team B Duplicates' as info,
    COUNT(*) as total_rows, 
    COUNT(DISTINCT CONCAT(employee_id, employee_name, region)) as unique_rows
FROM #Sales_Team_B;

-- =====================================================
-- EDGE CASES AND ADVANCED SCENARIOS
-- =====================================================

-- Edge Case 1: Empty result sets
SELECT customer_id, customer_name FROM #Customers_Current WHERE 1 = 0
INTERSECT
SELECT customer_id, customer_name FROM #Customers_Archive;

-- Edge Case 2: Single table INTERSECT (identity operation, removes duplicates)
SELECT customer_id, customer_name, region
FROM #Customers_Current
INTERSECT
SELECT customer_id, customer_name, region
FROM #Customers_Current;

-- Edge Case 3: Complex data types and calculations
WITH EnrichedCurrentCustomers AS (
    SELECT 
        customer_id,
        customer_name,
        UPPER(ISNULL(region, 'UNKNOWN')) as region_clean,
        CASE WHEN status = 'Active' THEN 1 ELSE 0 END as is_active
    FROM #Customers_Current
),
EnrichedArchiveCustomers AS (
    SELECT 
        customer_id,
        customer_name,
        UPPER(ISNULL(region, 'UNKNOWN')) as region_clean,
        CASE WHEN status = 'Active' THEN 1 ELSE 0 END as is_active
    FROM #Customers_Archive
)
SELECT customer_id, customer_name, region_clean, is_active
FROM EnrichedCurrentCustomers
INTERSECT
SELECT customer_id, customer_name, region_clean, is_active
FROM EnrichedArchiveCustomers;

-- =====================================================
-- PERFORMANCE COMPARISON: INTERSECT/EXCEPT vs JOIN
-- =====================================================

-- Performance test setup
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Method 1: INTERSECT (set-based operation)
SELECT customer_id, customer_name
FROM #Customers_Current
INTERSECT
SELECT customer_id, customer_name
FROM #Customers_Archive;

-- Method 2: INNER JOIN with DISTINCT (relational operation)
SELECT DISTINCT c1.customer_id, c1.customer_name
FROM #Customers_Current c1
INNER JOIN #Customers_Archive c2 
    ON c1.customer_id = c2.customer_id 
    AND c1.customer_name = c2.customer_name;

-- Method 3: EXISTS (often most efficient for large datasets)
SELECT DISTINCT customer_id, customer_name
FROM #Customers_Current c1
WHERE EXISTS (
    SELECT 1 
    FROM #Customers_Archive c2 
    WHERE c1.customer_id = c2.customer_id 
    AND c1.customer_name = c2.customer_name
);

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- =====================================================
-- BUSINESS USE CASES FOR INTERSECT/EXCEPT
-- =====================================================

-- Use Case 1: Data Quality - Find inconsistent records
-- Records that exist in both systems but with different attributes
WITH CurrentCustomers AS (
    SELECT customer_id, customer_name FROM #Customers_Current
),
ArchiveCustomers AS (
    SELECT customer_id, customer_name FROM #Customers_Archive
)
SELECT 
    'Customers in both systems' as analysis,
    COUNT(*) as record_count
FROM (
    SELECT customer_id, customer_name FROM CurrentCustomers
    INTERSECT
    SELECT customer_id, customer_name FROM ArchiveCustomers
) intersected
UNION ALL
SELECT 
    'Customers only in current' as analysis,
    COUNT(*) as record_count
FROM (
    SELECT customer_id, customer_name FROM CurrentCustomers
    EXCEPT
    SELECT customer_id, customer_name FROM ArchiveCustomers
) current_only
UNION ALL
SELECT 
    'Customers only in archive' as analysis,
    COUNT(*) as record_count
FROM (
    SELECT customer_id, customer_name FROM ArchiveCustomers
    EXCEPT
    SELECT customer_id, customer_name FROM CurrentCustomers
) archive_only;

-- Use Case 2: Migration Validation
-- Verify that all active customers from archive were migrated
SELECT 
    customer_id, 
    customer_name, 
    region, 
    'Missing from current system' as issue_type
FROM #Customers_Archive
WHERE status = 'Active'
EXCEPT
SELECT 
    customer_id, 
    customer_name, 
    region, 
    'Missing from current system' as issue_type
FROM #Customers_Current;

-- Use Case 3: Security Audit - Find unauthorized access
-- Compare current user permissions with approved baseline
CREATE TABLE #Current_Permissions (
    user_id INT,
    resource_name VARCHAR(50),
    permission_level VARCHAR(20)
);

CREATE TABLE #Baseline_Permissions (
    user_id INT,
    resource_name VARCHAR(50),
    permission_level VARCHAR(20)
);

-- Sample data
INSERT INTO #Current_Permissions VALUES
(1, 'Database_A', 'Read'),
(1, 'Database_A', 'Write'),
(2, 'Database_B', 'Read'),
(2, 'Database_C', 'Admin'),  -- Potentially unauthorized
(3, 'Database_A', 'Read');

INSERT INTO #Baseline_Permissions VALUES
(1, 'Database_A', 'Read'),
(1, 'Database_A', 'Write'),
(2, 'Database_B', 'Read'),
(3, 'Database_A', 'Read');

-- Find unauthorized permissions (in current but not in baseline)
SELECT 
    user_id, 
    resource_name, 
    permission_level,
    'UNAUTHORIZED ACCESS' as alert_type
FROM #Current_Permissions
EXCEPT
SELECT 
    user_id, 
    resource_name, 
    permission_level,
    'UNAUTHORIZED ACCESS' as alert_type
FROM #Baseline_Permissions;

-- Find missing permissions (in baseline but not current)
SELECT 
    user_id, 
    resource_name, 
    permission_level,
    'MISSING PERMISSION' as alert_type
FROM #Baseline_Permissions
EXCEPT
SELECT 
    user_id, 
    resource_name, 
    permission_level,
    'MISSING PERMISSION' as alert_type
FROM #Current_Permissions;

-- =====================================================
-- INTERSECT/EXCEPT BEST PRACTICES
-- =====================================================

/*
When to use INTERSECT:
✓ Finding exact matches between datasets
✓ Data validation and quality checks
✓ Comparing snapshots of data
✓ When you need automatic duplicate removal

When to use EXCEPT:
✓ Finding missing records
✓ Data migration validation
✓ Security audits
✓ Change detection between datasets

Performance Tips:
1. INTERSECT/EXCEPT remove duplicates automatically (like UNION)
2. Consider using EXISTS/NOT EXISTS for better performance on large datasets
3. Index the columns being compared
4. Use specific columns rather than SELECT * when possible
5. Be aware of NULL handling - NULLs are considered equal in INTERSECT/EXCEPT

NULL Handling Rules:
- NULL = NULL is TRUE in INTERSECT/EXCEPT (unlike regular comparisons)
- This makes them useful for comparing data with missing values
- Be careful when converting from JOIN-based logic

Memory and Performance:
- INTERSECT/EXCEPT may require sorting operations
- Can be memory intensive for large result sets
- Consider using EXISTS/NOT EXISTS for better performance
- Test with actual data volumes
*/

-- Performance comparison example
-- Large dataset simulation
WITH LargeSet1 AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as id,
        'Name_' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR) as name
    FROM #Customers_Current c1
    CROSS JOIN #Customers_Archive c2  -- Creates larger dataset
),
LargeSet2 AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as id,
        'Name_' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR) as name
    FROM #Customers_Archive c1
    CROSS JOIN #Customers_Current c2
)
-- Compare methods for finding common records
SELECT 'INTERSECT Method' as method, COUNT(*) as result_count
FROM (
    SELECT id FROM LargeSet1
    INTERSECT
    SELECT id FROM LargeSet2
) intersected
UNION ALL
SELECT 'EXISTS Method' as method, COUNT(*) as result_count
FROM (
    SELECT DISTINCT l1.id
    FROM LargeSet1 l1
    WHERE EXISTS (SELECT 1 FROM LargeSet2 l2 WHERE l1.id = l2.id)
) existed;

-- =====================================================
-- CLEANUP FOR INTERSECT/EXCEPT EXAMPLES
-- =====================================================
DROP TABLE #Customers_Current;
DROP TABLE #Customers_Archive;
DROP TABLE #Table_A;
DROP TABLE #Table_B;
DROP TABLE #Sales_Team_A;
DROP TABLE #Sales_Team_B;
DROP TABLE #Current_Permissions;
DROP TABLE #Baseline_Permissions;

/*
SUMMARY:

Performance Comparison:
- JOIN: Best for relational operations, single query execution, memory efficient
- UNION: Best for data consolidation, simple operations, multiple source combining
- INTERSECT: Best for finding exact matches, automatic duplicate removal, NULL-safe comparisons
- EXCEPT: Best for finding differences, missing data detection, migration validation

Choose JOIN when:
- Combining related entities
- Need columns from multiple tables
- Working with normalized data
- Need complex filtering and aggregation

Choose UNION when:
- Combining similar datasets
- Data consolidation from multiple sources
- Historical data integration
- Simple row combination

Choose INTERSECT when:
- Finding exact row matches between datasets
- Data validation and integrity checks
- Need automatic duplicate removal
- Comparing snapshots or versions

Choose EXCEPT when:
- Finding missing or unique records
- Migration validation
- Change detection
- Data cleanup operations

Key Performance Tips:
- Use UNION ALL instead of UNION when possible
- Properly index JOIN columns
- Filter data early in all operations
- Consider EXISTS/NOT EXISTS for better performance with INTERSECT/EXCEPT
- Be aware of NULL handling differences between operations
- Test with actual data volumes for performance optimization
*/
========

Performance Comparison:
- JOIN: Best for relational operations, single query execution, memory efficient
- UNION: Best for data consolidation, simple operations, multiple source combining

Choose JOIN when:
- Combining related entities
- Need columns from multiple tables
- Working with normalized data
- Need complex filtering and aggregation

Choose UNION when:
- Combining similar datasets
- Data consolidation from multiple sources
- Historical data integration
- Simple row combination

Key Performance Tips:
- Use UNION ALL instead of UNION when possible
- Properly index JOIN columns
- Filter data early in both operations
- Consider query execution plans for optimization
*/
