-- =====================================================
-- Query Execution Plans: Fabric SQL Server, PostgreSQL & Delta Tables
-- =====================================================
-- Performance Analysis and Optimization Guide
-- Technologies: Microsoft Fabric SQL Server, PostgreSQL, Delta Lake

-- =====================================================
-- WHAT IS EXPLAIN?
-- =====================================================

-- EXPLAIN shows the execution plan that the database query planner generates
-- for the supplied statement. The execution plan shows how tables will be
-- scanned, what join algorithms will be used, and estimated costs.

-- EXPLAIN ANALYZE goes one step further - it actually executes the query
-- and shows real execution times, actual row counts, and other runtime statistics.

-- =====================================================
-- TECHNOLOGY-SPECIFIC SYNTAX
-- =====================================================

-- PostgreSQL:       EXPLAIN [ANALYZE] [VERBOSE] [BUFFERS] query
-- SQL Server/Fabric: SET SHOWPLAN_ALL ON; query; SET SHOWPLAN_ALL OFF;
--                   Or use SQL Server Management Studio (Ctrl+M)
-- Delta Tables:     EXPLAIN [EXTENDED] query (in Spark SQL/Databricks)

-- =====================================================
-- SAMPLE DATA SETUP
-- =====================================================

-- Sample tables for demonstration across all three technologies
USE TestData;
GO

-- Drop tables if they exist
IF OBJECT_ID('dbo.employees', 'U') IS NOT NULL DROP TABLE dbo.employees;
IF OBJECT_ID('dbo.departments', 'U') IS NOT NULL DROP TABLE dbo.departments;
IF OBJECT_ID('dbo.sales_data', 'U') IS NOT NULL DROP TABLE dbo.sales_data;

-- Employees table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    manager_id INT
);

-- Departments table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(100),
    budget DECIMAL(15,2)
);

-- Sales data table (for Delta table examples)
CREATE TABLE sales_data (
    sale_id INT PRIMARY KEY,
    emp_id INT,
    sale_amount DECIMAL(12,2),
    sale_date DATE,
    region VARCHAR(50),
    product_category VARCHAR(50)
);

-- Insert sample data
INSERT INTO departments VALUES
(1, 'Engineering', 'New York', 5000000.00),
(2, 'Marketing', 'California', 2500000.00),
(3, 'Sales', 'Texas', 3000000.00),
(4, 'HR', 'Florida', 1500000.00);

INSERT INTO employees VALUES
(101, 'John Smith', 'Engineering', 75000.00, '2020-01-15', NULL),
(102, 'Jane Doe', 'Marketing', 65000.00, '2019-03-20', 101),
(103, 'Bob Wilson', 'Sales', 70000.00, '2021-05-10', 101),
(104, 'Alice Brown', 'Engineering', 85000.00, '2020-08-25', 101),
(105, 'Charlie Davis', 'HR', 60000.00, '2022-01-12', 102);

INSERT INTO sales_data VALUES
(1001, 103, 15000.00, '2024-01-15', 'North', 'Software'),
(1002, 103, 22000.00, '2024-02-20', 'South', 'Hardware'),
(1003, 104, 18000.00, '2024-01-25', 'East', 'Software'),
(1004, 105, 12000.00, '2024-03-10', 'West', 'Services');

-- Create indexes for performance testing
CREATE INDEX idx_emp_department ON employees(department);
CREATE INDEX idx_emp_salary ON employees(salary);
CREATE INDEX idx_sales_region ON sales_data(region);

-- =====================================================
-- POSTGRESQL EXAMPLES
-- =====================================================

-- EXAMPLE 1: Basic EXPLAIN
-- Shows estimated costs, row counts, and execution plan
EXPLAIN 
SELECT emp_name, salary 
FROM employees 
WHERE department = 'Engineering';

-- Expected Output:
-- Seq Scan on employees  (cost=0.00..250.00 rows=100 width=68)
--   Filter: ((department)::text = 'Engineering'::text)

-- EXAMPLE 2: EXPLAIN ANALYZE
-- Shows actual execution statistics
EXPLAIN ANALYZE
SELECT emp_name, salary 
FROM employees 
WHERE department = 'Engineering';

-- Expected Output:
-- Seq Scan on employees  (cost=0.00..250.00 rows=100 width=68) (actual time=0.123..5.456 rows=95 loops=1)
--   Filter: ((department)::text = 'Engineering'::text)
--   Rows Removed by Filter: 9905
-- Planning Time: 0.234 ms
-- Execution Time: 5.789 ms

-- EXAMPLE 3: EXPLAIN with JOIN
EXPLAIN ANALYZE
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
JOIN departments d ON e.department = d.dept_name
WHERE e.salary > 70000;

-- Expected Output shows join strategy (Hash Join, Nested Loop, etc.)

-- EXAMPLE 4: EXPLAIN with Complex Query
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    e.department,
    COUNT(*) as emp_count,
    AVG(e.salary) as avg_salary,
    MAX(e.salary) as max_salary
FROM employees e
WHERE e.hire_date >= '2020-01-01'
GROUP BY e.department
HAVING COUNT(*) > 5
ORDER BY avg_salary DESC;

-- =====================================================
-- MICROSOFT FABRIC SQL SERVER EXAMPLES
-- =====================================================

-- METHOD 1: Using SET SHOWPLAN_ALL (Works in both SQL Server and Fabric)
SET SHOWPLAN_ALL ON;
SELECT emp_name, salary 
FROM employees 
WHERE department = 'Engineering';
SET SHOWPLAN_ALL OFF;

-- METHOD 2: Using SET STATISTICS IO and TIME (Performance Analysis)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT emp_name, salary 
FROM employees 
WHERE department = 'Engineering';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- METHOD 3: Fabric-specific Query Insights
-- In Microsoft Fabric, use the Query Editor's "Explain Plan" feature
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
JOIN departments d ON e.department = d.dept_name
WHERE e.salary > 70000;

-- METHOD 4: Fabric SQL Analytics Endpoint Query Performance
-- Use Fabric's built-in performance monitoring
SET STATISTICS XML ON;
SELECT 
    s.region,
    COUNT(*) as sale_count,
    SUM(s.sale_amount) as total_sales,
    AVG(s.sale_amount) as avg_sale
FROM sales_data s
GROUP BY s.region
HAVING SUM(s.sale_amount) > 20000;
SET STATISTICS XML OFF;

-- METHOD 5: Fabric Warehouse Query Optimization
-- Leverage Fabric's automatic query optimization
WITH EmployeeSales AS (
    SELECT 
        e.emp_id,
        e.emp_name,
        e.department,
        SUM(s.sale_amount) as total_sales
    FROM employees e
    JOIN sales_data s ON e.emp_id = s.emp_id
    GROUP BY e.emp_id, e.emp_name, e.department
)
SELECT department, AVG(total_sales) as avg_dept_sales
FROM EmployeeSales
GROUP BY department;

-- =====================================================
-- DELTA TABLES EXAMPLES (Spark SQL/Databricks)
-- =====================================================

-- Delta tables are used in Databricks, Azure Synapse, and other Spark environments

-- EXAMPLE 1: Basic EXPLAIN for Delta table
-- Note: These examples would run in Databricks/Spark SQL environment
/*
EXPLAIN
SELECT emp_name, salary 
FROM delta.`/path/to/employees`
WHERE department = 'Engineering';
*/

-- EXAMPLE 2: EXPLAIN EXTENDED for detailed Delta optimization info
/*
EXPLAIN EXTENDED
SELECT e.emp_name, d.dept_name, e.salary
FROM delta.`/path/to/employees` e
JOIN delta.`/path/to/departments` d ON e.department = d.dept_name
WHERE e.salary > 70000;
*/

-- EXAMPLE 3: Delta table with partitioning analysis
/*
-- Create partitioned Delta table
CREATE TABLE employees_delta
USING DELTA
PARTITIONED BY (department)
AS SELECT * FROM employees;

EXPLAIN
SELECT emp_name, salary
FROM employees_delta
WHERE department = 'Engineering'
  AND hire_date >= '2020-01-01';
*/

-- EXAMPLE 4: Delta table optimization commands and analysis
/*
-- Optimize Delta table
OPTIMIZE employees_delta;

-- Z-order optimization for better query performance
OPTIMIZE employees_delta ZORDER BY (salary, hire_date);

-- Analyze query performance after optimization
EXPLAIN
SELECT emp_name, salary, hire_date
FROM employees_delta
WHERE salary > 70000 
  AND hire_date >= '2020-01-01'
ORDER BY salary DESC;
*/

-- EXAMPLE 5: Delta table time travel query analysis
/*
EXPLAIN
SELECT emp_name, salary
FROM employees_delta VERSION AS OF 0
WHERE department = 'Engineering';

-- Compare with current version
EXPLAIN
SELECT emp_name, salary
FROM employees_delta
WHERE department = 'Engineering';
*/

-- =====================================================
-- INTERPRETING EXECUTION PLANS
-- =====================================================

-- KEY METRICS TO UNDERSTAND:

-- 1. COST
--    - Estimated relative cost of the operation
--    - Lower is generally better
--    - Used by query planner to choose between alternatives

-- 2. ROWS
--    - Estimated number of rows to be processed
--    - Actual rows (in ANALYZE) vs estimated rows
--    - Large differences indicate poor statistics

-- 3. TIME
--    - Actual execution time (ANALYZE only)
--    - Helps identify slow operations
--    - Planning time vs execution time

-- 4. OPERATION TYPES:
--    - Seq Scan: Table scan (reads entire table)
--    - Index Scan: Uses index to find specific rows
--    - Index Only Scan: Gets data from index without table access
--    - Hash Join: Builds hash table for join
--    - Nested Loop: For each row in outer table, scan inner table
--    - Merge Join: Sorts both tables and merges

-- =====================================================
-- REAL-WORLD USE CASES BY TECHNOLOGY
-- =====================================================

-- USE CASE 1: Slow Query Investigation
-- Problem: Query takes 30 seconds to execute

-- Step 1: Get execution plan
EXPLAIN ANALYZE
SELECT e.emp_name, e.salary, d.dept_name, p.project_name
FROM employees e
JOIN employee_projects ep ON e.emp_id = ep.emp_id
JOIN projects p ON ep.project_id = p.project_id
JOIN departments d ON e.department = d.dept_name
WHERE e.salary > 50000
  AND p.start_date >= '2023-01-01'
  AND d.location = 'New York'
ORDER BY e.salary DESC;

-- Analysis reveals:
-- - Sequential scan on large employees table (no index on salary)
-- - Nested loop joins causing cartesian product
-- - No index on departments.location

-- Solutions:
-- CREATE INDEX idx_emp_salary ON employees(salary);
-- CREATE INDEX idx_dept_location ON departments(location);
-- CREATE INDEX idx_project_start_date ON projects(start_date);

-- USE CASE 2: Index Usage Verification
-- Check if queries are using indexes properly

EXPLAIN ANALYZE
SELECT * FROM employees 
WHERE department = 'Engineering' 
  AND salary BETWEEN 60000 AND 80000;

-- Good: Index Scan on idx_emp_department
-- Bad: Seq Scan on employees (index not used)

-- USE CASE 3: JOIN Strategy Optimization
-- Compare different join approaches

-- Hash Join (good for large tables)
EXPLAIN ANALYZE
SELECT /*+ USE_HASH(e d) */ e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.department = d.dept_name;

-- Nested Loop (good when one table is small)
EXPLAIN ANALYZE
SELECT /*+ USE_NL(e d) */ e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.department = d.dept_name
WHERE d.dept_id = 1;

-- USE CASE 4: Aggregate Query Optimization
EXPLAIN ANALYZE
SELECT 
    department,
    COUNT(*) as emp_count,
    AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING COUNT(*) > 10;

-- Look for:
-- - Sort operations (expensive for large datasets)
-- - Hash aggregate vs Group aggregate
-- - Index usage for GROUP BY

-- =====================================================
-- TECHNOLOGY-SPECIFIC OPTIMIZATION STRATEGIES
-- =====================================================

-- FABRIC SQL SERVER OPTIMIZATION
-- Leverage Fabric's cloud-native features
SET STATISTICS IO ON;

-- Use columnstore indexes for analytical workloads
CREATE CLUSTERED COLUMNSTORE INDEX CCI_sales_data ON sales_data;

-- Query with columnstore optimization
SELECT region, SUM(sale_amount) as total_sales
FROM sales_data
WHERE sale_date >= '2024-01-01'
GROUP BY region;

SET STATISTICS IO OFF;

-- POSTGRESQL OPTIMIZATION
-- PostgreSQL-specific optimization techniques
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    e.department,
    COUNT(*) as emp_count,
    AVG(e.salary) as avg_salary
FROM employees e
WHERE e.hire_date >= '2020-01-01'
GROUP BY e.department;

-- PostgreSQL vacuum and analyze for statistics
-- VACUUM ANALYZE employees;
-- VACUUM ANALYZE departments;

-- DELTA TABLE OPTIMIZATION
-- Delta-specific optimization strategies
/*
-- Delta table maintenance
VACUUM delta.`/path/to/employees` RETAIN 168 HOURS;

-- Optimize with Z-ordering
OPTIMIZE delta.`/path/to/employees`
ZORDER BY (department, salary);

-- Analyze table statistics
ANALYZE TABLE employees_delta COMPUTE STATISTICS;
*/

-- =====================================================
-- PERFORMANCE OPTIMIZATION BASED ON EXPLAIN
-- =====================================================

-- OPTIMIZATION 1: Missing Indexes
-- Problem: Seq Scan on large table
-- Before:
EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 80000;
-- Shows: Seq Scan on employees (cost=0.00..1650.00 rows=1000)

-- Solution: Add index
-- CREATE INDEX idx_emp_salary ON employees(salary);

-- After:
EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 80000;
-- Shows: Index Scan using idx_emp_salary (cost=0.42..123.45 rows=1000)

-- OPTIMIZATION 2: Query Rewriting
-- Problem: Inefficient subquery
-- Before:
EXPLAIN ANALYZE
SELECT emp_name 
FROM employees 
WHERE department IN (
    SELECT dept_name 
    FROM departments 
    WHERE location = 'New York'
);

-- Better: Use JOIN instead
EXPLAIN ANALYZE
SELECT DISTINCT e.emp_name 
FROM employees e
JOIN departments d ON e.department = d.dept_name
WHERE d.location = 'New York';

-- OPTIMIZATION 3: Limiting Result Sets
-- Problem: Processing too many rows
-- Before:
EXPLAIN ANALYZE
SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- Better: Use LIMIT for top results
EXPLAIN ANALYZE
SELECT emp_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 10;

-- ================================================================================
-- EXPLAIN OUTPUT COMPONENTS
-- ================================================================================

-- POSTGRESQL EXPLAIN OUTPUT BREAKDOWN:
--
-- Node Type (Operation)
-- ├── Cost: startup cost..total cost
-- ├── rows=estimated_rows
-- ├── width=average_row_width
-- ├── actual time=startup..total (ANALYZE only)
-- ├── actual rows=actual_count (ANALYZE only)
-- ├── loops=loop_count (ANALYZE only)
-- └── Additional details (Filter, Index Cond, etc.)

-- EXAMPLE BREAKDOWN:
-- Hash Join  (cost=123.45..567.89 rows=1000 width=64) (actual time=12.34..56.78 rows=995 loops=1)
-- │
-- ├── Hash Cond: (e.department = d.dept_name)
-- ├── ->  Seq Scan on employees e  (cost=0.00..250.00 rows=10000 width=32)
-- │       ├── Filter: (salary > 50000)
-- │       └── Rows Removed by Filter: 5000
-- └── ->  Hash  (cost=50.00..50.00 rows=50 width=32)
--         └── Seq Scan on departments d  (cost=0.00..50.00 rows=50 width=32)

-- =====================================================
-- TECHNOLOGY-SPECIFIC PERFORMANCE PATTERNS
-- =====================================================

-- FABRIC SQL SERVER PATTERNS
-- Pattern 1: Columnstore scan optimization
-- Good: Columnstore segment elimination
-- Bad: Row-mode processing on analytical queries

-- Pattern 2: Fabric warehouse distribution
-- Good: Proper data distribution across compute nodes
-- Bad: Data skew causing hot spots

-- POSTGRESQL PATTERNS
-- Pattern 1: Index usage patterns
-- Good: Index Only Scan, Index Scan
-- Bad: Sequential Scan on large tables

-- Pattern 2: Join algorithm selection
-- Good: Hash Join for large tables, Nested Loop for small
-- Bad: Nested Loop on large datasets

-- DELTA TABLE PATTERNS
-- Pattern 1: File pruning efficiency
-- Good: Efficient predicate pushdown and file skipping
-- Bad: Full table scan across all Delta files

-- Pattern 2: Clustering and Z-order benefits
-- Good: Data co-location improving scan efficiency
-- Bad: Random data layout requiring more I/O

-- =====================================================
-- COMMON PERFORMANCE PATTERNS
-- =====================================================

-- PATTERN 1: Table Scans on Large Tables
-- Red Flag: "Seq Scan" on tables with millions of rows
-- Solution: Add appropriate indexes

-- PATTERN 2: Nested Loops with Large Tables
-- Red Flag: "Nested Loop" with high actual times
-- Solution: Ensure join columns are indexed, consider hash joins

-- PATTERN 3: Sorts on Large Result Sets
-- Red Flag: "Sort" operations with high memory usage
-- Solution: Add indexes that match ORDER BY, use LIMIT

-- PATTERN 4: High Filter Selectivity
-- Red Flag: "Rows Removed by Filter: 999999"
-- Solution: Move filters to WHERE clause, add indexes

-- =====================================================
-- ADVANCED TECHNIQUES BY TECHNOLOGY
-- =====================================================

-- FABRIC SQL SERVER ADVANCED TECHNIQUES
-- Technique 1: Query Store analysis
-- Use Fabric's Query Store for historical performance comparison
SELECT 
    e.emp_name, 
    SUM(s.sale_amount) as total_sales
FROM employees e
JOIN sales_data s ON e.emp_id = s.emp_id
GROUP BY e.emp_name
HAVING SUM(s.sale_amount) > 30000;

-- Technique 2: Fabric intelligent query processing
-- Leverage adaptive joins and memory grant feedback

-- POSTGRESQL ADVANCED TECHNIQUES
-- Technique 1: Custom cost parameters tuning
-- EXPLAIN (ANALYZE, BUFFERS)
-- SET random_page_cost = 1.1; -- SSD optimization
-- SET effective_cache_size = '4GB';

-- Technique 2: Parallel query analysis
EXPLAIN (ANALYZE, BUFFERS)
SELECT department, AVG(salary)
FROM employees
GROUP BY department;

-- DELTA TABLE ADVANCED TECHNIQUES
-- Technique 1: Bloom filter effectiveness
/*
OPTIMIZE delta.`/path/to/employees`
ZORDER BY (department)
WITH BLOOM FILTER ON (emp_id);

EXPLAIN
SELECT * FROM delta.`/path/to/employees`
WHERE emp_id = 101;
*/

-- Technique 2: Liquid clustering (if supported)
/*
CREATE TABLE employees_clustered
USING DELTA
CLUSTER BY (department, hire_date)
AS SELECT * FROM employees;
*/

-- =====================================================
-- ADVANCED EXPLAIN TECHNIQUES
-- =====================================================

-- TECHNIQUE 1: Comparing Query Alternatives
-- Test multiple approaches to same problem

-- Option A: Subquery
EXPLAIN ANALYZE
SELECT emp_name 
FROM employees 
WHERE emp_id IN (
    SELECT emp_id FROM employee_projects WHERE hours_worked > 40
);

-- Option B: EXISTS
EXPLAIN ANALYZE
SELECT emp_name 
FROM employees e
WHERE EXISTS (
    SELECT 1 FROM employee_projects ep 
    WHERE ep.emp_id = e.emp_id AND ep.hours_worked > 40
);

-- Option C: JOIN
EXPLAIN ANALYZE
SELECT DISTINCT e.emp_name 
FROM employees e
JOIN employee_projects ep ON e.emp_id = ep.emp_id
WHERE ep.hours_worked > 40;

-- TECHNIQUE 2: Analyzing Parameter Sensitivity
-- Check how query performance varies with different parameter values

EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 50000;  -- Returns 50% of data

EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 90000;  -- Returns 5% of data

-- TECHNIQUE 3: Buffer Analysis (PostgreSQL)
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.department = d.dept_name;

-- Shows:
-- Buffers: shared hit=123 read=45 dirtied=2 written=1

-- =====================================================
-- TECHNOLOGY-SPECIFIC TROUBLESHOOTING
-- =====================================================

-- FABRIC SQL SERVER TROUBLESHOOTING
-- Issue 1: Poor columnstore performance
SET STATISTICS IO ON;
SELECT region, COUNT(*) 
FROM sales_data
WHERE sale_date >= '2024-01-01';
-- Check for row-mode processing vs batch-mode

-- Issue 2: Fabric compute scaling
-- Monitor query performance across different Fabric capacity units
-- Use Fabric monitoring tools for resource utilization

-- POSTGRESQL TROUBLESHOOTING  
-- Issue 1: Poor join performance
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.department = d.dept_name;
-- Look for hash vs nested loop joins

-- Issue 2: Statistics outdated
-- Check if ANALYZE needs to be run
-- SELECT schemaname, tablename, last_analyze 
-- FROM pg_stat_user_tables;

-- DELTA TABLE TROUBLESHOOTING
-- Issue 1: Too many small files
/*
-- Check file statistics
DESCRIBE DETAIL delta.`/path/to/employees`;

-- Optimize to reduce small files
OPTIMIZE delta.`/path/to/employees`;
*/

-- Issue 2: Inefficient predicate pushdown
/*
EXPLAIN
SELECT * FROM delta.`/path/to/employees`
WHERE department = 'Engineering';
-- Check for proper partition pruning
*/

-- =====================================================
-- TROUBLESHOOTING WITH EXPLAIN
-- =====================================================

-- ISSUE 1: Query Suddenly Became Slow
-- Check if execution plan changed
-- Compare current plan with historical plans
-- Look for missing or unused indexes

-- ISSUE 2: High CPU Usage
-- Look for expensive operations:
-- - Large sorts
-- - Hash joins with very large hash tables
-- - Seq scans on large tables

-- ISSUE 3: High I/O Wait
-- Check buffer statistics:
-- - High "read" values indicate disk I/O
-- - Low "hit" ratio suggests poor caching
-- - Consider index optimization

-- ISSUE 4: Memory Issues
-- Look for:
-- - Large hash tables
-- - Sort operations that spill to disk
-- - Consider increasing work_mem (PostgreSQL)

-- =====================================================
-- TECHNOLOGY-SPECIFIC BEST PRACTICES
-- =====================================================

-- FABRIC SQL SERVER BEST PRACTICES
-- 1. Use Fabric's automatic statistics and query optimization
-- 2. Monitor through Fabric monitoring portal
-- 3. Leverage columnstore for analytical workloads
-- 4. Use proper data distribution strategies
-- 5. Monitor compute resource utilization

-- POSTGRESQL BEST PRACTICES
-- 1. Regular VACUUM and ANALYZE operations
-- 2. Use pg_stat_statements for query analysis
-- 3. Monitor buffer cache hit ratios
-- 4. Tune work_mem and other parameters
-- 5. Use connection pooling for high concurrency

-- DELTA TABLE BEST PRACTICES
-- 1. Regular OPTIMIZE operations to compact files
-- 2. Use Z-ordering for commonly filtered columns
-- 3. Implement proper partitioning strategy
-- 4. Monitor file sizes and counts
-- 5. Use time travel judiciously (impacts storage)

-- =====================================================
-- BEST PRACTICES FOR USING EXPLAIN
-- =====================================================

-- 1. Always use EXPLAIN ANALYZE for accurate performance data
-- 2. Run queries multiple times to get consistent results
-- 3. Use realistic data volumes for testing
-- 4. Update table statistics regularly (ANALYZE table)
-- 5. Compare before/after when making optimizations
-- 6. Focus on operations with highest costs or times
-- 7. Consider the entire query, not just individual operations
-- 8. Test with production-like data and load

-- =====================================================
-- TECHNOLOGY-SPECIFIC TOOLS
-- =====================================================

-- MICROSOFT FABRIC SQL SERVER:
-- - Fabric Portal Query Insights
-- - SQL Server Management Studio (SSMS) for Fabric endpoints
-- - Fabric Monitoring and Metrics
-- - Query Store integration
-- - Power BI for performance visualization

-- POSTGRESQL:
-- - pgAdmin Query Analyzer
-- - pg_stat_statements extension
-- - auto_explain module
-- - EXPLAIN visualization tools
-- - pg_stat_user_tables for statistics

-- DELTA TABLES:
-- - Databricks Query Profiler
-- - Spark SQL EXPLAIN commands
-- - Delta Lake file statistics (DESCRIBE DETAIL)
-- - Azure Synapse Analytics query insights
-- - Spark UI for detailed execution plans

-- =====================================================
-- SAMPLE OPTIMIZATION WORKFLOW BY TECHNOLOGY
-- =====================================================

-- FABRIC SQL SERVER WORKFLOW
-- 1. Use Fabric monitoring to identify slow queries
-- 2. Analyze with SET STATISTICS IO/TIME
-- 3. Consider columnstore indexes for analytical queries
-- 4. Leverage Fabric's automatic tuning recommendations
-- 5. Monitor performance through Fabric portal
-- 6. Scale compute resources if needed

-- POSTGRESQL WORKFLOW  
-- 1. Enable pg_stat_statements for query tracking
-- 2. Run EXPLAIN (ANALYZE, BUFFERS) on slow queries
-- 3. Check for missing indexes and update statistics
-- 4. Tune PostgreSQL configuration parameters
-- 5. Monitor ongoing performance with pg_stat views
-- 6. Consider partitioning for very large tables

-- DELTA TABLE WORKFLOW
-- 1. Monitor Delta table file statistics
-- 2. Use EXPLAIN to analyze query plans
-- 3. Implement Z-ordering for frequently filtered columns
-- 4. Regular OPTIMIZE operations to compact files
-- 5. Monitor Spark UI for detailed execution metrics
-- 6. Consider partitioning strategy for large tables

-- =====================================================
-- SAMPLE OPTIMIZATION WORKFLOW
-- =====================================================

-- 1. Identify slow query
-- 2. Run EXPLAIN ANALYZE
-- 3. Identify bottlenecks:
--    a. Table scans on large tables
--    b. Expensive joins
--    c. Large sorts
--    d. Poor selectivity filters
-- 4. Apply fixes:
--    a. Add indexes
--    b. Rewrite query
--    c. Update statistics
--    d. Partition tables
-- 5. Re-run EXPLAIN ANALYZE
-- 6. Verify improvement
-- 7. Monitor in production

-- =====================================================
-- CONCLUSION & KEY TAKEAWAYS
-- =====================================================

-- Query execution plan analysis across Fabric SQL Server, PostgreSQL, and Delta Tables:

-- ✓ Understanding technology-specific execution patterns
-- ✓ Leveraging cloud-native optimization features (Fabric)
-- ✓ Traditional RDBMS optimization techniques (PostgreSQL)
-- ✓ Big data and lakehouse optimization strategies (Delta)
-- ✓ Cross-platform performance monitoring approaches

-- FABRIC SQL SERVER: Focus on columnstore, compute scaling, cloud optimization
-- POSTGRESQL: Emphasize indexing, statistics, and configuration tuning  
-- DELTA TABLES: Optimize file layout, partitioning, and Spark execution

-- Remember:
-- - Each technology has unique optimization opportunities
-- - Use native monitoring tools for best insights
-- - Consider data patterns and access methods
-- - Test optimizations in production-like environments
-- - Monitor long-term performance trends

-- Quick verification queries
SELECT 'Fabric/SQL Server' as technology, COUNT(*) as emp_count FROM employees;
-- PostgreSQL equivalent: SELECT 'PostgreSQL' as technology, COUNT(*) as emp_count FROM employees;
-- Delta equivalent: SELECT 'Delta Tables' as technology, COUNT(*) as emp_count FROM delta.employees;
