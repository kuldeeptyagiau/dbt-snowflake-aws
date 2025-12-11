-- =====================================================
-- SQL Server: Top 3 Customers by Revenue in Each Region
-- =====================================================
-- Author: SQL Analysis Examples
-- Purpose: Demonstrate window functions for ranking customers by revenue within regions
-- Date: 2025-01-10

USE TestData;
GO



-- =====================================================
-- 1. CREATE SAMPLE TABLES AND DATA
-- =====================================================

-- Drop tables if they exist
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Regions', 'U') IS NOT NULL DROP TABLE dbo.Regions;

-- Create Regions table
CREATE TABLE dbo.Regions (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL
);

-- Create Customers table
CREATE TABLE dbo.Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    region_id INT NOT NULL,
    customer_type VARCHAR(20) DEFAULT 'Regular',
    signup_date DATE NOT NULL,
    FOREIGN KEY (region_id) REFERENCES dbo.Regions(region_id)
);

-- Create Orders table
CREATE TABLE dbo.Orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_amount DECIMAL(12,2) NOT NULL,
    product_category VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id)
);


select * from customers
-- =====================================================
-- 2. INSERT SAMPLE DATA
-- =====================================================

-- Insert Regions
INSERT INTO dbo.Regions (region_id, region_name, country) VALUES
(1, 'North America', 'USA'),
(2, 'Europe', 'UK'),
(3, 'Asia Pacific', 'Australia'),
(4, 'Latin America', 'Brazil'),
(5, 'Middle East', 'UAE');

-- Insert Customers
INSERT INTO dbo.Customers (customer_id, customer_name, region_id, customer_type, signup_date) VALUES
-- North America (Region 1)
(101, 'TechCorp Solutions', 1, 'Enterprise', '2023-01-15'),
(102, 'DataMax Inc', 1, 'Enterprise', '2023-02-20'),
(103, 'CloudFirst LLC', 1, 'SMB', '2023-03-10'),
(104, 'InnovateTech', 1, 'Regular', '2023-04-05'),
(105, 'MegaSystems Corp', 1, 'Enterprise', '2023-01-25'),

-- Europe (Region 2)
(201, 'EuroTech Limited', 2, 'Enterprise', '2023-01-30'),
(202, 'London Analytics', 2, 'SMB', '2023-02-15'),
(203, 'Continental Data', 2, 'Enterprise', '2023-03-20'),
(204, 'Nordic Solutions', 2, 'Regular', '2023-04-10'),
(205, 'Alpine Systems', 2, 'SMB', '2023-02-28'),

-- Asia Pacific (Region 3)
(301, 'Pacific Digital', 3, 'Enterprise', '2023-01-20'),
(302, 'Aussie Analytics', 3, 'SMB', '2023-02-25'),
(303, 'Tokyo Tech Hub', 3, 'Enterprise', '2023-03-15'),
(304, 'Singapore Systems', 3, 'Regular', '2023-04-20'),
(305, 'Melbourne Data Co', 3, 'SMB', '2023-03-05'),

-- Latin America (Region 4)
(401, 'Brasil Tech SA', 4, 'Enterprise', '2023-01-10'),
(402, 'Sao Paulo Digital', 4, 'SMB', '2023-02-18'),
(403, 'Latin Data Corp', 4, 'Regular', '2023-03-25'),
(404, 'Rio Systems', 4, 'SMB', '2023-04-15'),

-- Middle East (Region 5)
(501, 'Dubai Tech Hub', 5, 'Enterprise', '2023-01-05'),
(502, 'Emirates Data', 5, 'SMB', '2023-02-12'),
(503, 'Gulf Analytics', 5, 'Regular', '2023-03-30');

-- Insert Orders (with varying amounts to create revenue differences)
INSERT INTO dbo.Orders (order_id, customer_id, order_date, order_amount, product_category) VALUES
-- North America Orders
(1001, 101, '2024-01-15', 125000.00, 'Software'),
(1002, 101, '2024-02-20', 95000.00, 'Consulting'),
(1003, 101, '2024-03-10', 78000.00, 'Support'),
(1004, 102, '2024-01-25', 145000.00, 'Software'),
(1005, 102, '2024-02-28', 67000.00, 'Training'),
(1006, 103, '2024-01-30', 45000.00, 'Software'),
(1007, 103, '2024-03-15', 32000.00, 'Support'),
(1008, 104, '2024-02-05', 23000.00, 'Software'),
(1009, 105, '2024-01-20', 189000.00, 'Enterprise'),
(1010, 105, '2024-03-25', 234000.00, 'Consulting'),

-- Europe Orders
(1011, 201, '2024-01-18', 156000.00, 'Software'),
(1012, 201, '2024-02-22', 89000.00, 'Support'),
(1013, 202, '2024-01-28', 67000.00, 'Software'),
(1014, 203, '2024-02-15', 178000.00, 'Enterprise'),
(1015, 203, '2024-03-20', 45000.00, 'Training'),
(1016, 204, '2024-02-10', 28000.00, 'Software'),
(1017, 205, '2024-01-25', 52000.00, 'Consulting'),

-- Asia Pacific Orders
(1018, 301, '2024-01-22', 198000.00, 'Enterprise'),
(1019, 301, '2024-03-18', 123000.00, 'Software'),
(1020, 302, '2024-02-08', 45000.00, 'Software'),
(1021, 303, '2024-01-30', 167000.00, 'Software'),
(1022, 303, '2024-02-25', 89000.00, 'Support'),
(1023, 304, '2024-03-12', 34000.00, 'Training'),
(1024, 305, '2024-02-18', 56000.00, 'Software'),

-- Latin America Orders
(1025, 401, '2024-01-20', 134000.00, 'Software'),
(1026, 401, '2024-03-15', 78000.00, 'Support'),
(1027, 402, '2024-02-12', 43000.00, 'Software'),
(1028, 403, '2024-01-25', 29000.00, 'Training'),
(1029, 404, '2024-02-28', 38000.00, 'Software'),

-- Middle East Orders
(1030, 501, '2024-01-15', 145000.00, 'Enterprise'),
(1031, 501, '2024-02-20', 67000.00, 'Consulting'),
(1032, 502, '2024-01-30', 34000.00, 'Software'),
(1033, 503, '2024-02-25', 28000.00, 'Support');

-- =====================================================
-- 3. MAIN QUERY: TOP 3 CUSTOMERS BY REVENUE PER REGION
-- =====================================================

-- Method 1: Using ROW_NUMBER() with CTE (Recommended approach)
WITH CustomerRevenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.customer_type,
        r.region_name,
        r.country,
        SUM(o.order_amount) AS total_revenue,
        AVG(o.order_amount) AS avg_order_value,
        COUNT(o.order_id) AS total_orders,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS latest_order_date,
        ROW_NUMBER() OVER (
            PARTITION BY r.region_name 
            ORDER BY sum(o.order_amount) DESC
        ) AS revenue_rank
    FROM dbo.Customers c
    inner  JOIN dbo.Regions r ON c.region_id = r.region_id
    inner JOIN dbo.Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.customer_type ,r.region_name, r.country
)
SELECT 
    region_name,
    country,
    revenue_rank,
    customer_name,
    customer_type,
    total_revenue,
    total_orders,
    avg_order_value,
    first_order_date,
    latest_order_date,
    cast(SUM(total_revenue) OVER (PARTITION BY region_name)  AS DECIMAL(5,2) )as rev_per_reg ,
    -- Calculate percentage of region's total revenue
    CAST(total_revenue * 100.0 / SUM(total_revenue) OVER (PARTITION BY region_name) AS DECIMAL(5,2)) AS pct_of_region_revenue
FROM CustomerRevenue
-- WHERE revenue_rank <= 3
ORDER BY region_name, revenue_rank;

-- =====================================================
-- 4. ALTERNATIVE METHODS AND VARIATIONS
-- =====================================================

-- Method 2: Using RANK() instead of ROW_NUMBER() (handles ties differently)
WITH CustomerRevenueRank AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        r.region_name,
        SUM(o.order_amount) AS total_revenue,
        RANK() OVER (
            PARTITION BY r.region_name 
            ORDER BY SUM(o.order_amount) DESC
        ) AS revenue_rank
    FROM dbo.Customers c
    INNER JOIN dbo.Regions r ON c.region_id = r.region_id
    INNER JOIN dbo.Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, r.region_name
)
SELECT *
FROM CustomerRevenueRank
WHERE revenue_rank <= 3
ORDER BY region_name, revenue_rank;

-- Method 3: Using TOP with OVER clause (SQL Server specific)
SELECT TOP (15) WITH TIES -- 3 per region × 5 regions = 15
    r.region_name,
    c.customer_name,
    SUM(o.order_amount) AS total_revenue,
    ROW_NUMBER() OVER (
        PARTITION BY r.region_name 
        ORDER BY SUM(o.order_amount) DESC
    ) AS rn
FROM dbo.Customers c
INNER JOIN dbo.Regions r ON c.region_id = r.region_id
INNER JOIN dbo.Orders o ON c.customer_id = o.customer_id
GROUP BY r.region_name, c.customer_name, c.customer_id
ORDER BY r.region_name, SUM(o.order_amount) DESC;

-- =====================================================
-- 5. SCENARIO USE CASES
-- =====================================================

-- Scenario 1: Sales Performance Analysis
-- Find top performers for sales team recognition and bonus calculation
SELECT 
    'Sales Performance Analysis' AS scenario,
    region_name,
    customer_name,
    total_revenue,
    CASE 
        WHEN revenue_rank = 1 THEN 'Gold Tier - 15% Bonus'
        WHEN revenue_rank = 2 THEN 'Silver Tier - 10% Bonus'
        WHEN revenue_rank = 3 THEN 'Bronze Tier - 5% Bonus'
    END AS bonus_tier
FROM (
    SELECT 
        c.customer_name,
        r.region_name,
        SUM(o.order_amount) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY r.region_name 
            ORDER BY SUM(o.order_amount) DESC
        ) AS revenue_rank
    FROM dbo.Customers c
    INNER JOIN dbo.Regions r ON c.region_id = r.region_id
    INNER JOIN dbo.Orders o ON c.customer_id = o.customer_id
    WHERE o.order_date >= '2024-01-01'
    GROUP BY c.customer_id, c.customer_name, r.region_name
) ranked
WHERE revenue_rank <= 3
ORDER BY region_name, revenue_rank;

-- Scenario 2: Account Management Priority
-- Identify high-value accounts for dedicated account managers
WITH TopAccounts AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        r.region_name,
        c.customer_type,
        SUM(o.order_amount) AS total_revenue,
        COUNT(o.order_id) AS total_orders,
        DATEDIFF(day, MIN(o.order_date), MAX(o.order_date)) AS customer_lifespan_days,
        ROW_NUMBER() OVER (
            PARTITION BY r.region_name 
            ORDER BY SUM(o.order_amount) DESC
        ) AS revenue_rank
    FROM dbo.Customers c
    INNER JOIN dbo.Regions r ON c.region_id = r.region_id
    INNER JOIN dbo.Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, r.region_name, c.customer_type
)
SELECT 
    'Account Management Priority' AS scenario,
    region_name,
    customer_name,
    customer_type,
    total_revenue,
    total_orders,
    customer_lifespan_days,
    CASE 
        WHEN revenue_rank = 1 THEN 'Senior Account Manager'
        WHEN revenue_rank = 2 THEN 'Account Manager'
        WHEN revenue_rank = 3 THEN 'Junior Account Manager'
    END AS assigned_manager_level
FROM TopAccounts
WHERE revenue_rank <= 3
ORDER BY region_name, revenue_rank;

-- Scenario 3: Marketing Campaign Targeting
-- Identify customers for premium product launches by region
WITH MarketingTargets AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        r.region_name,
        r.country,
        SUM(o.order_amount) AS total_revenue,
        AVG(o.order_amount) AS avg_order_value,
        MAX(o.order_date) AS last_purchase_date,
        ROW_NUMBER() OVER (
            PARTITION BY r.region_name 
            ORDER BY SUM(o.order_amount) DESC
        ) AS revenue_rank
    FROM dbo.Customers c
    INNER JOIN dbo.Regions r ON c.region_id = r.region_id
    INNER JOIN dbo.Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, r.region_name, r.country
)
SELECT 
    'Marketing Campaign Targeting' AS scenario,
    region_name,
    country,
    customer_name,
    total_revenue,
    avg_order_value,
    last_purchase_date,
    CASE 
        WHEN DATEDIFF(day, last_purchase_date, GETDATE()) <= 30 THEN 'Active - High Priority'
        WHEN DATEDIFF(day, last_purchase_date, GETDATE()) <= 90 THEN 'Recent - Medium Priority'
        ELSE 'Dormant - Re-engagement Needed'
    END AS campaign_priority
FROM MarketingTargets
WHERE revenue_rank <= 3
ORDER BY region_name, revenue_rank;

-- Scenario 4: Quarterly Business Review
-- Comprehensive analysis for executive reporting
WITH QuarterlyAnalysis AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        r.region_name,
        c.customer_type,
        SUM(o.order_amount) AS total_revenue,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN o.order_date >= DATEADD(quarter, -1, GETDATE()) THEN o.order_amount ELSE 0 END) AS q_current_revenue,
        SUM(CASE WHEN o.order_date >= DATEADD(quarter, -2, GETDATE()) AND o.order_date < DATEADD(quarter, -1, GETDATE()) THEN o.order_amount ELSE 0 END) AS q_previous_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY r.region_name 
            ORDER BY SUM(o.order_amount) DESC
        ) AS revenue_rank
    FROM dbo.Customers c
    INNER JOIN dbo.Regions r ON c.region_id = r.region_id
    INNER JOIN dbo.Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, r.region_name, c.customer_type
)
SELECT 
    'Quarterly Business Review' AS scenario,
    region_name,
    customer_name,
    customer_type,
    total_revenue,
    total_orders,
    q_current_revenue,
    q_previous_revenue,
    CASE 
        WHEN q_previous_revenue > 0 THEN 
            CAST((q_current_revenue - q_previous_revenue) * 100.0 / q_previous_revenue AS DECIMAL(10,2))
        ELSE NULL 
    END AS quarter_growth_pct,
    CASE 
        WHEN q_current_revenue > q_previous_revenue THEN 'Growing'
        WHEN q_current_revenue = q_previous_revenue THEN 'Stable'
        ELSE 'Declining'
    END AS trend_direction
FROM QuarterlyAnalysis
WHERE revenue_rank <= 3
ORDER BY region_name, revenue_rank;

-- =====================================================
-- 6. PERFORMANCE CONSIDERATIONS AND BEST PRACTICES
-- =====================================================

-- Create indexes for better performance
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_OrderDate 
ON dbo.Orders (customer_id, order_date) 
INCLUDE (order_amount);

CREATE NONCLUSTERED INDEX IX_Customers_RegionID 
ON dbo.Customers (region_id) 
INCLUDE (customer_name, customer_type);

-- Query with execution plan analysis
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Run the main query and analyze performance
WITH CustomerRevenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        r.region_name,
        SUM(o.order_amount) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY r.region_name 
            ORDER BY SUM(o.order_amount) DESC
        ) AS revenue_rank
    FROM dbo.Customers c
    INNER JOIN dbo.Regions r ON c.region_id = r.region_id
    INNER JOIN dbo.Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, r.region_name
)
SELECT *
FROM CustomerRevenue
WHERE revenue_rank <= 3
ORDER BY region_name, revenue_rank;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- =====================================================
-- 7. SUMMARY AND KEY TAKEAWAYS
-- =====================================================

/*
KEY LEARNING POINTS:

1. WINDOW FUNCTIONS:
   - ROW_NUMBER(): Assigns unique sequential numbers (no ties)
   - RANK(): Allows ties, skips subsequent ranks
   - DENSE_RANK(): Allows ties, no gaps in ranking

2. PERFORMANCE TIPS:
   - Use appropriate indexes on join and filter columns
   - Consider partitioning for very large tables
   - Use STATISTICS IO/TIME to monitor performance

3. BUSINESS SCENARIOS:
   - Sales performance analysis and bonus calculations
   - Account management and resource allocation
   - Marketing campaign targeting
   - Executive reporting and trend analysis

4. SQL SERVER SPECIFIC FEATURES:
   - TOP WITH TIES clause
   - Comprehensive date functions (DATEDIFF, DATEADD)
   - Rich analytical capabilities

5. BEST PRACTICES:
   - Always include ORDER BY in window functions
   - Use meaningful aliases for better readability
   - Consider business logic for tie-breaking
   - Document complex queries thoroughly
*/

-- View final sample data to verify results
SELECT 'Sample Data Verification' AS info;
SELECT TOP 10 * FROM dbo.Customers ORDER BY customer_id;
SELECT TOP 10 * FROM dbo.Orders ORDER BY order_date DESC;
SELECT TOP 10 * FROM dbo.Regions ORDER BY region_id;

-- Ties value will also be included
SELECT TOP 10 with ties * FROM dbo.Customers ORDER BY customer_id;



