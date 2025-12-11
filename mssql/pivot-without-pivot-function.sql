-- =====================================================
-- SQL Server: PIVOT Without PIVOT Function - Concise Examples & Use Cases
-- =====================================================
USE TestData;
GO

-- =====================================================
-- 1. SAMPLE DATA SETUP
-- =====================================================

-- Sales Data
IF OBJECT_ID('dbo.Sales_Data', 'U') IS NOT NULL DROP TABLE dbo.Sales_Data;
CREATE TABLE Sales_Data (sales_rep VARCHAR(50), quarter VARCHAR(10), sales_amount DECIMAL(10,2));
INSERT INTO Sales_Data VALUES
('John', 'Q1', 15000), ('John', 'Q2', 18000), ('John', 'Q3', 22000), ('John', 'Q4', 25000),
('Sarah', 'Q1', 12000), ('Sarah', 'Q2', 16000), ('Sarah', 'Q3', 19000), ('Sarah', 'Q4', 21000),
('Mike', 'Q1', 14000), ('Mike', 'Q2', 17000), ('Mike', 'Q3', 20000), ('Mike', 'Q4', 23000);

-- Product Sales
IF OBJECT_ID('dbo.Product_Sales', 'U') IS NOT NULL DROP TABLE dbo.Product_Sales;
CREATE TABLE Product_Sales (product_name VARCHAR(50), store_location VARCHAR(50), units_sold INT);
INSERT INTO Product_Sales VALUES
('Laptop', 'New York', 150), ('Laptop', 'California', 200), ('Laptop', 'Texas', 120),
('Mouse', 'New York', 300), ('Mouse', 'California', 250), ('Mouse', 'Texas', 180),
('Keyboard', 'New York', 200), ('Keyboard', 'California', 180), ('Keyboard', 'Texas', 160);

-- Employee Skills
IF OBJECT_ID('dbo.Employee_Skills', 'U') IS NOT NULL DROP TABLE dbo.Employee_Skills;
CREATE TABLE Employee_Skills (emp_name VARCHAR(50), skill_name VARCHAR(50), proficiency_level INT);
INSERT INTO Employee_Skills VALUES
('Alice', 'SQL', 5), ('Alice', 'Python', 4), ('Alice', 'Java', 3),
('Bob', 'SQL', 4), ('Bob', 'Python', 5), ('Bob', 'JavaScript', 4),
('Carol', 'SQL', 3), ('Carol', 'Java', 5), ('Carol', 'C++', 4);

-- =====================================================
-- 4. ADVANCED TECHNIQUES
-- =====================================================

-- Multi-Aggregation Pivot (Count + Sum + Avg)
SELECT product_name,
    COUNT(CASE WHEN store_location = 'New York' THEN 1 END) AS NY_Count,
    SUM(CASE WHEN store_location = 'New York' THEN units_sold ELSE 0 END) AS NY_Units,
    AVG(CASE WHEN store_location = 'New York' THEN units_sold END) AS NY_Avg,
    COUNT(CASE WHEN store_location = 'California' THEN 1 END) AS CA_Count,
    SUM(CASE WHEN store_location = 'California' THEN units_sold ELSE 0 END) AS CA_Units,
    AVG(CASE WHEN store_location = 'California' THEN units_sold END) AS CA_Avg
FROM Product_Sales
GROUP BY product_name;

-- String Concatenation Pivot
SELECT emp_name,
    STRING_AGG(CASE WHEN proficiency_level >= 4 
                    THEN skill_name + '(' + CAST(proficiency_level AS VARCHAR) + ')' 
                    END, ', ') AS Advanced_Skills,
    STRING_AGG(CASE WHEN proficiency_level < 4 
                    THEN skill_name + '(' + CAST(proficiency_level AS VARCHAR) + ')' 
                    END, ', ') AS Basic_Skills
FROM Employee_Skills
GROUP BY emp_name;

SELECT emp_name,
    STRING_AGG(skill_name ,', ') AS Advanced_Skills,
    STRING_AGG(proficiency_level, ', ') AS Basic_Skills
FROM Employee_Skills
GROUP BY emp_name;

select * FROM Employee_Skills

select * from Sales_Data

-- Conditional Pivot with Percentiles
WITH SalesRanks AS (
    SELECT sales_rep, quarter, sales_amount,
           PERCENT_RANK() OVER (PARTITION BY quarter ORDER BY sales_amount) AS pct_rank,
           RANK() OVER (PARTITION BY quarter ORDER BY sales_amount) AS rank
    FROM Sales_Data
)
SELECT sales_rep,
    MAX(CASE WHEN quarter = 'Q1' THEN ROUND(pct_rank * 100, 2) END) AS Q1_Percentile,
    MAX(CASE WHEN quarter = 'Q2' THEN ROUND(pct_rank * 100, 2) END) AS Q2_Percentile,
    MAX(CASE WHEN quarter = 'Q3' THEN ROUND(pct_rank * 100, 2) END) AS Q3_Percentile,
    MAX(CASE WHEN quarter = 'Q4' THEN ROUND(pct_rank * 100, 2) END) AS Q4_Percentile
FROM SalesRanks
GROUP BY sales_rep;

-- =====================================================
-- 5. SQL SERVER PIVOT FUNCTION COMPARISON
-- =====================================================

-- Traditional Method
SELECT sales_rep,
    SUM(CASE WHEN quarter = 'Q1' THEN sales_amount ELSE 0 END) AS Q1,
    SUM(CASE WHEN quarter = 'Q2' THEN sales_amount ELSE 0 END) AS Q2,
    SUM(CASE WHEN quarter = 'Q3' THEN sales_amount ELSE 0 END) AS Q3,
    SUM(CASE WHEN quarter = 'Q4' THEN sales_amount ELSE 0 END) AS Q4
FROM Sales_Data
GROUP BY sales_rep;

-- PIVOT Function Method
SELECT sales_rep, [Q1], [Q2], [Q3], [Q4]
FROM (SELECT sales_rep, quarter, sales_amount FROM Sales_Data) src
PIVOT (SUM(sales_amount) FOR quarter IN ([Q1], [Q2], [Q3], [Q4])) piv;

-- Dynamic PIVOT Example
DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
SELECT @columns = STRING_AGG(QUOTENAME(quarter), ', ') FROM (SELECT DISTINCT quarter FROM Sales_Data) q;
SET @sql = 'SELECT sales_rep, ' + @columns + ' FROM (SELECT sales_rep, quarter, sales_amount FROM Sales_Data) src PIVOT (SUM(sales_amount) FOR quarter IN (' + @columns + ')) piv;';
PRINT @sql; -- Would execute with: EXEC sp_executesql @sql;



-- =====================================================
-- 6. EDGE CASES & NULL HANDLING
-- =====================================================

-- Handle NULLs properly
SELECT sales_rep,
    ISNULL(SUM(CASE WHEN quarter = 'Q1' THEN sales_amount END), 0) AS Q1,
    ISNULL(SUM(CASE WHEN quarter = 'Q2' THEN sales_amount END), 0) AS Q2,
    ISNULL(SUM(CASE WHEN quarter = 'Q3' THEN sales_amount END), 0) AS Q3,
    ISNULL(SUM(CASE WHEN quarter = 'Q4' THEN sales_amount END), 0) AS Q4
FROM Sales_Data
GROUP BY sales_rep;

-- Multiple Values per Cell
SELECT product_name,
    COUNT(CASE WHEN store_location = 'New York' THEN 1 END) AS NY_Stores,
    STRING_AGG(CASE WHEN store_location = 'New York' THEN CAST(units_sold AS VARCHAR) END, ', ') AS NY_Details,
    COUNT(CASE WHEN store_location = 'California' THEN 1 END) AS CA_Stores,
    STRING_AGG(CASE WHEN store_location = 'California' THEN CAST(units_sold AS VARCHAR) END, ', ') AS CA_Details
FROM Product_Sales
GROUP BY product_name;

-- =====================================================
-- 7. PERFORMANCE & BEST PRACTICES
-- =====================================================

-- Index recommendations
CREATE NONCLUSTERED INDEX IX_Sales_Quarter ON Sales_Data(quarter) INCLUDE (sales_rep, sales_amount);
CREATE NONCLUSTERED INDEX IX_Product_Location ON Product_Sales(store_location) INCLUDE (product_name, units_sold);

-- Performance comparison query
SET STATISTICS IO ON;
SELECT sales_rep, SUM(CASE WHEN quarter = 'Q1' THEN sales_amount ELSE 0 END) AS Q1
FROM Sales_Data GROUP BY sales_rep;
SET STATISTICS IO OFF;

-- =====================================================
-- 8. REAL-WORLD SCENARIOS
-- =====================================================

-- Financial P&L Pivot
WITH SampleFinancials AS (
    SELECT 'Revenue' AS account_type, 'Jan' AS month, 100000.00 AS amount
    UNION ALL SELECT 'Revenue', 'Feb', 110000.00
    UNION ALL SELECT 'Expenses', 'Jan', 75000.00
    UNION ALL SELECT 'Expenses', 'Feb', 80000.00
)
SELECT account_type,
    SUM(CASE WHEN month = 'Jan' THEN amount ELSE 0 END) AS January,
    SUM(CASE WHEN month = 'Feb' THEN amount ELSE 0 END) AS February,
    SUM(amount) AS Total
FROM SampleFinancials
GROUP BY account_type;

-- Customer Satisfaction Analysis
WITH SatisfactionData AS (
    SELECT 'Product A' AS product, 5 AS rating, 50 AS responses
    UNION ALL SELECT 'Product A', 4, 30
    UNION ALL SELECT 'Product A', 3, 15
    UNION ALL SELECT 'Product B', 5, 40
    UNION ALL SELECT 'Product B', 4, 35
)
SELECT product,
    SUM(CASE WHEN rating = 5 THEN responses ELSE 0 END) AS Excellent,
    SUM(CASE WHEN rating = 4 THEN responses ELSE 0 END) AS Good,
    SUM(CASE WHEN rating = 3 THEN responses ELSE 0 END) AS Average,
    SUM(responses) AS Total_Responses,
    ROUND((SUM(CASE WHEN rating >= 4 THEN responses ELSE 0 END) * 100.0 / SUM(responses)), 2) AS Satisfaction_Pct
FROM SatisfactionData
GROUP BY product;

-- =====================================================
-- KEY TAKEAWAYS
-- =====================================================
/*
WHEN TO USE CASE WHEN METHOD:
✓ Database compatibility (works everywhere)
✓ Complex calculations during pivot
✓ Multiple aggregations needed
✓ Dynamic conditions required

WHEN TO USE PIVOT FUNCTION:
✓ Simple pivoting with known columns
✓ SQL Server environment
✓ Performance critical scenarios
✓ Cleaner syntax preferred

PERFORMANCE TIPS:
- Index on pivot columns
- Use appropriate aggregation functions
- Consider materialized views for frequent queries
- Test both methods with actual data volumes
*/

-- =====================================================
-- 9. UNPIVOT EXAMPLES (Converting Columns to Rows)
-- =====================================================

-- UNPIVOT is the reverse of PIVOT - converts columns back to rows
-- Sample pivoted data to demonstrate UNPIVOT

-- Create a pivoted sales table for UNPIVOT examples
IF OBJECT_ID('dbo.Sales_Pivoted', 'U') IS NOT NULL DROP TABLE dbo.Sales_Pivoted;
CREATE TABLE Sales_Pivoted (
    sales_rep VARCHAR(50),
    Q1 DECIMAL(10,2),
    Q2 DECIMAL(10,2),
    Q3 DECIMAL(10,2),
    Q4 DECIMAL(10,2)
);

INSERT INTO Sales_Pivoted VALUES
('John', 15000, 18000, 22000, 25000),
('Sarah', 12000, 16000, 19000, 21000),
('Mike', 14000, 17000, 20000, 23000);

-- METHOD 1: UNPIVOT using UNION ALL (Traditional Method)
SELECT sales_rep, 'Q1' AS quarter, Q1 AS sales_amount FROM Sales_Pivoted
UNION ALL
SELECT sales_rep, 'Q2' AS quarter, Q2 AS sales_amount FROM Sales_Pivoted
UNION ALL
SELECT sales_rep, 'Q3' AS quarter, Q3 AS sales_amount FROM Sales_Pivoted
UNION ALL
SELECT sales_rep, 'Q4' AS quarter, Q4 AS sales_amount FROM Sales_Pivoted
ORDER BY sales_rep, quarter;

-- METHOD 2: SQL Server UNPIVOT Function
SELECT sales_rep, quarter, sales_amount
FROM (
    SELECT sales_rep, Q1, Q2, Q3, Q4
    FROM Sales_Pivoted
) src
UNPIVOT (
    sales_amount FOR quarter IN (Q1, Q2, Q3, Q4)
) AS unpvt
ORDER BY sales_rep, quarter;

-- METHOD 3: UNPIVOT with NULL handling
-- Create sample with some NULL values
IF OBJECT_ID('dbo.Sales_With_Nulls', 'U') IS NOT NULL DROP TABLE dbo.Sales_With_Nulls;
CREATE TABLE Sales_With_Nulls (
    sales_rep VARCHAR(50),
    Q1 DECIMAL(10,2),
    Q2 DECIMAL(10,2),
    Q3 DECIMAL(10,2),
    Q4 DECIMAL(10,2)
);

INSERT INTO Sales_With_Nulls VALUES
('John', 15000, 18000, NULL, 25000),
('Sarah', 12000, NULL, 19000, 21000),
('Mike', NULL, 17000, 20000, 23000);

-- UNPIVOT automatically excludes NULL values
SELECT sales_rep, quarter, sales_amount
FROM Sales_With_Nulls
UNPIVOT (
    sales_amount FOR quarter IN (Q1, Q2, Q3, Q4)
) AS unpvt
ORDER BY sales_rep, quarter;

-- To include NULLs, use UNION ALL method
SELECT sales_rep, quarter, sales_amount
FROM (
    SELECT sales_rep, 'Q1' AS quarter, Q1 AS sales_amount FROM Sales_With_Nulls
    UNION ALL
    SELECT sales_rep, 'Q2' AS quarter, Q2 AS sales_amount FROM Sales_With_Nulls
    UNION ALL
    SELECT sales_rep, 'Q3' AS quarter, Q3 AS sales_amount FROM Sales_With_Nulls
    UNION ALL
    SELECT sales_rep, 'Q4' AS quarter, Q4 AS sales_amount FROM Sales_With_Nulls
) unpivoted
ORDER BY sales_rep, quarter;

-- =====================================================
-- UNPIVOT BUSINESS SCENARIOS
-- =====================================================

-- Scenario 1: Financial Report Analysis
-- Convert quarterly financials from columns to rows for time-series analysis
IF OBJECT_ID('dbo.Financial_Summary', 'U') IS NOT NULL DROP TABLE dbo.Financial_Summary;
CREATE TABLE Financial_Summary (
    account_type VARCHAR(50),
    Q1_2024 DECIMAL(15,2),
    Q2_2024 DECIMAL(15,2),
    Q3_2024 DECIMAL(15,2),
    Q4_2024 DECIMAL(15,2)
);

INSERT INTO Financial_Summary VALUES
('Revenue', 1000000, 1200000, 1100000, 1300000),
('Expenses', 750000, 850000, 800000, 900000),
('Profit', 250000, 350000, 300000, 400000);

-- UNPIVOT for trend analysis
SELECT account_type, quarter, amount,
    LAG(amount) OVER (PARTITION BY account_type ORDER BY quarter) AS prev_quarter,
    amount - LAG(amount) OVER (PARTITION BY account_type ORDER BY quarter) AS quarter_change
FROM Financial_Summary
UNPIVOT (
    amount FOR quarter IN (Q1_2024, Q2_2024, Q3_2024, Q4_2024)
) AS unpvt
ORDER BY account_type, quarter;

-- Scenario 2: Survey Response Analysis
-- Convert Likert scale responses from wide to long format
IF OBJECT_ID('dbo.Survey_Wide', 'U') IS NOT NULL DROP TABLE dbo.Survey_Wide;
CREATE TABLE Survey_Wide (
    respondent_id INT,
    Question_1 INT,
    Question_2 INT,
    Question_3 INT,
    Question_4 INT
);

INSERT INTO Survey_Wide VALUES
(1, 5, 4, 3, 5),
(2, 4, 4, 4, 3),
(3, 3, 5, 4, 4);

-- UNPIVOT for detailed analysis
SELECT respondent_id, question, response_value,
    CASE 
        WHEN response_value >= 4 THEN 'Positive'
        WHEN response_value = 3 THEN 'Neutral'
        ELSE 'Negative'
    END AS response_category
FROM Survey_Wide
UNPIVOT (
    response_value FOR question IN (Question_1, Question_2, Question_3, Question_4)
) AS unpvt
ORDER BY respondent_id, question;

-- Scenario 3: Multi-metric Performance Data
-- Convert performance metrics from columns to rows
IF OBJECT_ID('dbo.Performance_Metrics', 'U') IS NOT NULL DROP TABLE dbo.Performance_Metrics;
CREATE TABLE Performance_Metrics (
    department VARCHAR(50),
    Sales_Target DECIMAL(12,2),
    Sales_Actual DECIMAL(12,2),
    Cost_Budget DECIMAL(12,2),
    Cost_Actual DECIMAL(12,2)
);

INSERT INTO Performance_Metrics VALUES
('Engineering', 500000, 520000, 2000000, 1950000),
('Sales', 1200000, 1180000, 800000, 850000),
('Marketing', 300000, 350000, 500000, 480000);

-- UNPIVOT with calculated performance indicators
WITH UnpivotedMetrics AS (
    SELECT department, metric_type, amount
    FROM Performance_Metrics
    UNPIVOT (
        amount FOR metric_type IN (Sales_Target, Sales_Actual, Cost_Budget, Cost_Actual)
    ) AS unpvt
)
SELECT 
    department,
    MAX(CASE WHEN metric_type = 'Sales_Target' THEN amount END) AS sales_target,
    MAX(CASE WHEN metric_type = 'Sales_Actual' THEN amount END) AS sales_actual,
    MAX(CASE WHEN metric_type = 'Cost_Budget' THEN amount END) AS cost_budget,
    MAX(CASE WHEN metric_type = 'Cost_Actual' THEN amount END) AS cost_actual,
    -- Performance calculations
    ROUND((MAX(CASE WHEN metric_type = 'Sales_Actual' THEN amount END) / 
           MAX(CASE WHEN metric_type = 'Sales_Target' THEN amount END)) * 100, 2) AS sales_performance_pct,
    ROUND((MAX(CASE WHEN metric_type = 'Cost_Actual' THEN amount END) / 
           MAX(CASE WHEN metric_type = 'Cost_Budget' THEN amount END)) * 100, 2) AS cost_performance_pct
FROM UnpivotedMetrics
GROUP BY department;

-- =====================================================
-- ADVANCED UNPIVOT TECHNIQUES
-- =====================================================

-- Multiple Column UNPIVOT
-- UNPIVOT multiple related columns simultaneously
IF OBJECT_ID('dbo.Sales_Multi_Metrics', 'U') IS NOT NULL DROP TABLE dbo.Sales_Multi_Metrics;
CREATE TABLE Sales_Multi_Metrics (
    sales_rep VARCHAR(50),
    Q1_Amount DECIMAL(10,2),
    Q1_Count INT,
    Q2_Amount DECIMAL(10,2),
    Q2_Count INT,
    Q3_Amount DECIMAL(10,2),
    Q3_Count INT
);

INSERT INTO Sales_Multi_Metrics VALUES
('John', 15000, 12, 18000, 15, 22000, 18),
('Sarah', 12000, 10, 16000, 13, 19000, 16);

-- UNPIVOT both amount and count
SELECT sales_rep, quarter, amount, transaction_count
FROM (
    SELECT sales_rep,
        'Q1' AS quarter, Q1_Amount AS amount, Q1_Count AS transaction_count
    FROM Sales_Multi_Metrics
    UNION ALL
    SELECT sales_rep,
        'Q2' AS quarter, Q2_Amount AS amount, Q2_Count AS transaction_count
    FROM Sales_Multi_Metrics
    UNION ALL
    SELECT sales_rep,
        'Q3' AS quarter, Q3_Amount AS amount, Q3_Count AS transaction_count
    FROM Sales_Multi_Metrics
) unpivoted
ORDER BY sales_rep, quarter;

-- Dynamic UNPIVOT using CROSS APPLY and VALUES
SELECT sales_rep, quarter, sales_amount
FROM Sales_Pivoted
CROSS APPLY (
    VALUES 
        ('Q1', Q1),
        ('Q2', Q2),
        ('Q3', Q3),
        ('Q4', Q4)
) AS unpvt(quarter, sales_amount)
WHERE sales_amount IS NOT NULL
ORDER BY sales_rep, quarter;

-- =====================================================
-- UNPIVOT PERFORMANCE CONSIDERATIONS
-- =====================================================

-- Create index for UNPIVOT operations
CREATE INDEX IX_Sales_Pivoted_Rep ON Sales_Pivoted(sales_rep);

-- Performance comparison: UNPIVOT vs UNION ALL
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Method 1: UNPIVOT (usually more efficient)
SELECT sales_rep, quarter, sales_amount
FROM Sales_Pivoted
UNPIVOT (sales_amount FOR quarter IN (Q1, Q2, Q3, Q4)) AS unpvt;

-- Method 2: UNION ALL (more flexible but potentially slower)
SELECT sales_rep, 'Q1' AS quarter, Q1 AS sales_amount FROM Sales_Pivoted
UNION ALL
SELECT sales_rep, 'Q2' AS quarter, Q2 AS sales_amount FROM Sales_Pivoted
UNION ALL
SELECT sales_rep, 'Q3' AS quarter, Q3 AS sales_amount FROM Sales_Pivoted
UNION ALL
SELECT sales_rep, 'Q4' AS quarter, Q4 AS sales_amount FROM Sales_Pivoted;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- =====================================================
-- UNPIVOT BEST PRACTICES
-- =====================================================

/*
WHEN TO USE UNPIVOT:
✓ Converting wide data format to long format
✓ Normalizing denormalized data for analysis
✓ Time series analysis from pivoted data
✓ Data warehouse ETL processes
✓ Reporting and visualization preparation

UNPIVOT vs UNION ALL:
- UNPIVOT: Cleaner syntax, potentially better performance, SQL Server specific
- UNION ALL: More flexible, works in all databases, handles complex transformations

PERFORMANCE TIPS:
- Index the grouping columns (sales_rep in examples)
- Consider data volume when choosing approach
- UNPIVOT automatically excludes NULLs
- Use UNION ALL when you need to include NULLs or apply filters per column
*/

-- Quick verification
SELECT 'Data Summary' AS info;
SELECT COUNT(*) AS sales_records FROM Sales_Data;
SELECT COUNT(*) AS product_records FROM Product_Sales;
SELECT COUNT(*) AS skill_records FROM Employee_Skills;
SELECT COUNT(*) AS pivoted_records FROM Sales_Pivoted;
