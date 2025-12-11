/*
=====================================================
User Analytics & Churn Analysis - Simplified Examples
=====================================================

This document provides practical examples for user analytics including:
1. Churn Analysis
2. Daily Active Users Running Total
3. Moving 7-day Distinct User Count
4. Frequent Item Combinations
5. Consecutive Monthly Purchasers
6. Month-over-Month Product Growth
*/

-- =====================================================
-- SAMPLE DATA SETUP
-- =====================================================

-- Users table
CREATE TABLE #Users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50),
    registration_date DATE,
    status VARCHAR(20)
);

-- User activities table
CREATE TABLE #User_Activities (
    user_id INT,
    activity_date DATE,
    activity_type VARCHAR(50)
);

-- Orders and order items
CREATE TABLE #Orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2)
);

CREATE TABLE #Order_Items (
    order_id INT,
    product_id INT,
    product_name VARCHAR(50),
    quantity INT,
    price DECIMAL(10,2)
);

-- Product sales
CREATE TABLE #Product_Sales (
    product_id INT,
    product_name VARCHAR(50),
    sale_date DATE,
    quantity_sold INT,
    revenue DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO #Users VALUES
(1, 'john_doe', '2024-01-15', 'active'),
(2, 'jane_smith', '2024-02-01', 'active'),
(3, 'bob_johnson', '2024-03-10', 'churned'),
(4, 'alice_brown', '2024-01-20', 'active'),
(5, 'charlie_davis', '2024-04-05', 'churned');

-- Sample activities (last 60 days)
INSERT INTO #User_Activities VALUES
-- Active users
(1, DATEADD(day, -1, GETDATE()), 'login'),
(1, DATEADD(day, -2, GETDATE()), 'page_view'),
(1, DATEADD(day, -5, GETDATE()), 'login'),
(2, DATEADD(day, -3, GETDATE()), 'login'),
(2, DATEADD(day, -7, GETDATE()), 'purchase'),
(4, DATEADD(day, -2, GETDATE()), 'login'),
(4, DATEADD(day, -10, GETDATE()), 'login'),

-- Churned users (no recent activity)
(3, DATEADD(day, -45, GETDATE()), 'login'),
(3, DATEADD(day, -50, GETDATE()), 'page_view'),
(5, DATEADD(day, -35, GETDATE()), 'login');

-- Sample orders
INSERT INTO #Orders VALUES
(101, 1, '2024-10-01', 150.00),
(102, 2, '2024-10-15', 200.00),
(103, 4, '2024-11-01', 300.00),
(104, 1, '2024-11-15', 180.00),
(105, 2, '2024-12-01', 220.00),
(106, 4, '2024-09-15', 120.00),
(107, 2, '2024-09-20', 90.00);

-- Sample order items
INSERT INTO #Order_Items VALUES
(101, 1, 'Laptop', 1, 100.00),
(101, 2, 'Mouse', 1, 50.00),
(102, 1, 'Laptop', 1, 100.00),
(102, 3, 'Keyboard', 1, 100.00),
(103, 2, 'Mouse', 2, 100.00),
(103, 3, 'Keyboard', 2, 200.00),
(104, 1, 'Laptop', 1, 100.00),
(104, 4, 'Monitor', 1, 80.00),
(105, 1, 'Laptop', 1, 100.00),
(105, 2, 'Mouse', 1, 50.00),
(105, 3, 'Keyboard', 1, 70.00),
(106, 2, 'Mouse', 1, 50.00),
(106, 4, 'Monitor', 1, 70.00),
(107, 2, 'Mouse', 1, 50.00),
(107, 3, 'Keyboard', 1, 40.00);

-- Sample product sales
INSERT INTO #Product_Sales VALUES
(1, 'Laptop', '2024-09-01', 10, 1000.00),
(1, 'Laptop', '2024-10-01', 15, 1500.00),
(1, 'Laptop', '2024-11-01', 12, 1200.00),
(1, 'Laptop', '2024-12-01', 18, 1800.00),
(2, 'Mouse', '2024-09-01', 25, 1250.00),
(2, 'Mouse', '2024-10-01', 30, 1500.00),
(2, 'Mouse', '2024-11-01', 28, 1400.00),
(2, 'Mouse', '2024-12-01', 35, 1750.00),
(3, 'Keyboard', '2024-09-01', 20, 1600.00),
(3, 'Keyboard', '2024-10-01', 22, 1760.00),
(3, 'Keyboard', '2024-11-01', 25, 2000.00),
(3, 'Keyboard', '2024-12-01', 30, 2400.00);

-- =====================================================
-- 1. CHURN ANALYSIS - 3 EXAMPLES
-- =====================================================

-- Example 1: Activity-Based Churn (No activity in last 30 days)
SELECT 
    u.user_id,
    u.username,
    MAX(ua.activity_date) as last_activity_date,
    DATEDIFF(day, MAX(ua.activity_date), GETDATE()) as days_since_last_activity,
    'Activity Churn' as churn_type
FROM #Users u
INNER JOIN #User_Activities ua ON u.user_id = ua.user_id
GROUP BY u.user_id, u.username
HAVING MAX(ua.activity_date) < DATEADD(day, -30, GETDATE())
ORDER BY days_since_last_activity DESC;

-- Example 2: Purchase-Based Churn (No orders in last 60 days)
SELECT 
    u.user_id,
    u.username,
    MAX(o.order_date) as last_order_date,
    DATEDIFF(day, MAX(o.order_date), GETDATE()) as days_since_last_order,
    'Purchase Churn' as churn_type
FROM #Users u
INNER JOIN #Orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username
HAVING MAX(o.order_date) < DATEADD(day, -60, GETDATE())
ORDER BY days_since_last_order DESC;

-- Example 3: Status-Based Churn (Users marked as churned)
SELECT 
    u.user_id,
    u.username,
    u.status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM #User_Activities ua WHERE ua.user_id = u.user_id)
        THEN MAX(ua.activity_date)
        ELSE NULL
    END as last_activity_date,
    'Status Churn' as churn_type
FROM #Users u
LEFT JOIN #User_Activities ua ON u.user_id = ua.user_id
WHERE u.status = 'churned'
GROUP BY u.user_id, u.username, u.status
ORDER BY u.user_id;

-- =====================================================
-- 2. RUNNING TOTAL OF DAILY ACTIVE USERS
-- =====================================================

WITH DailyActiveUsers AS (
    SELECT 
        activity_date,
        COUNT(DISTINCT user_id) as daily_active_users
    FROM #User_Activities
    WHERE activity_date >= DATEADD(day, -30, GETDATE())
    GROUP BY activity_date
)
SELECT 
    activity_date,
    daily_active_users,
    SUM(daily_active_users) OVER (
        ORDER BY activity_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as running_total_dau
FROM DailyActiveUsers
ORDER BY activity_date;

-- =====================================================
-- 3. MOVING 7-DAY DISTINCT USER COUNT
-- =====================================================

WITH DailyUsers AS (
    SELECT 
        activity_date,
        COUNT(DISTINCT user_id) as daily_users
    FROM #User_Activities
    WHERE activity_date >= DATEADD(day, -30, GETDATE())
    GROUP BY activity_date
),
Moving7DayUsers AS (
    SELECT 
        ua.activity_date,
        COUNT(DISTINCT ua.user_id) as distinct_users_7day
    FROM #User_Activities ua
    WHERE ua.activity_date >= DATEADD(day, -30, GETDATE())
    AND EXISTS (
        SELECT 1 FROM #User_Activities ua2 
        WHERE ua2.user_id = ua.user_id
        AND ua2.activity_date BETWEEN DATEADD(day, -6, ua.activity_date) AND ua.activity_date
    )
    GROUP BY ua.activity_date
)
SELECT 
    du.activity_date,
    du.daily_users,
    ISNULL(m7.distinct_users_7day, 0) as moving_7day_users,
    AVG(du.daily_users) OVER (
        ORDER BY du.activity_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_7day_avg
FROM DailyUsers du
LEFT JOIN Moving7DayUsers m7 ON du.activity_date = m7.activity_date
ORDER BY du.activity_date;

-- =====================================================
-- 4. MOST FREQUENT COMBINATION OF PURCHASED ITEMS
-- =====================================================

-- Find pairs of products purchased together
WITH ProductPairs AS (
    SELECT 
        oi1.product_name as product_1,
        oi2.product_name as product_2,
        COUNT(*) as times_purchased_together
    FROM #Order_Items oi1
    INNER JOIN #Order_Items oi2 ON oi1.order_id = oi2.order_id
    WHERE oi1.product_id < oi2.product_id  -- Avoid duplicate pairs
    GROUP BY oi1.product_name, oi2.product_name
)
SELECT 
    product_1,
    product_2,
    times_purchased_together,
    RANK() OVER (ORDER BY times_purchased_together DESC) as popularity_rank
FROM ProductPairs
ORDER BY times_purchased_together DESC;

-- Find triplets of products purchased together
WITH ProductTriplets AS (
    SELECT 
        oi1.product_name as product_1,
        oi2.product_name as product_2,
        oi3.product_name as product_3,
        COUNT(*) as times_purchased_together
    FROM #Order_Items oi1
    INNER JOIN #Order_Items oi2 ON oi1.order_id = oi2.order_id
    INNER JOIN #Order_Items oi3 ON oi1.order_id = oi3.order_id
    WHERE oi1.product_id < oi2.product_id 
      AND oi2.product_id < oi3.product_id
    GROUP BY oi1.product_name, oi2.product_name, oi3.product_name
)
SELECT TOP 5
    product_1,
    product_2,
    product_3,
    times_purchased_together
FROM ProductTriplets
ORDER BY times_purchased_together DESC;

-- =====================================================
-- 5. USERS WHO PURCHASED IN 3 CONSECUTIVE MONTHS
-- =====================================================

WITH UserMonthlyPurchases AS (
    SELECT 
        o.user_id,
        u.username,
        YEAR(o.order_date) as purchase_year,
        MONTH(o.order_date) as purchase_month,
        COUNT(o.order_id) as orders_in_month,
        SUM(o.total_amount) as total_spent_in_month
    FROM #Orders o
    INNER JOIN #Users u ON o.user_id = u.user_id
    GROUP BY o.user_id, u.username, YEAR(o.order_date), MONTH(o.order_date)
),
ConsecutiveMonths AS (
    SELECT 
        user_id,
        username,
        purchase_year,
        purchase_month,
        orders_in_month,
        total_spent_in_month,
        -- Calculate consecutive month groups
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY purchase_year, purchase_month) as month_sequence,
        (purchase_year * 12 + purchase_month) - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY purchase_year, purchase_month) as consecutive_group
    FROM UserMonthlyPurchases
)
SELECT 
    user_id,
    username,
    MIN(CONCAT(purchase_year, '-', FORMAT(purchase_month, '00'))) as start_month,
    MAX(CONCAT(purchase_year, '-', FORMAT(purchase_month, '00'))) as end_month,
    COUNT(*) as consecutive_months,
    SUM(orders_in_month) as total_orders,
    SUM(total_spent_in_month) as total_spent
FROM ConsecutiveMonths
GROUP BY user_id, username, consecutive_group
HAVING COUNT(*) >= 3  -- 3 or more consecutive months
ORDER BY consecutive_months DESC, total_spent DESC;

-- =====================================================
-- 6. MONTH-OVER-MONTH GROWTH FOR EACH PRODUCT
-- =====================================================

WITH MonthlyProductSales AS (
    SELECT 
        product_id,
        product_name,
        YEAR(sale_date) as sale_year,
        MONTH(sale_date) as sale_month,
        SUM(quantity_sold) as total_quantity,
        SUM(revenue) as total_revenue
    FROM #Product_Sales
    GROUP BY product_id, product_name, YEAR(sale_date), MONTH(sale_date)
),
ProductGrowth AS (
    SELECT 
        product_id,
        product_name,
        sale_year,
        sale_month,
        total_quantity,
        total_revenue,
        -- Previous month values
        LAG(total_quantity) OVER (PARTITION BY product_id ORDER BY sale_year, sale_month) as prev_month_quantity,
        LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY sale_year, sale_month) as prev_month_revenue,
        -- Year-over-year comparison
        LAG(total_revenue, 12) OVER (PARTITION BY product_id ORDER BY sale_year, sale_month) as same_month_last_year_revenue
    FROM MonthlyProductSales
)
SELECT 
    product_name,
    CONCAT(sale_year, '-', FORMAT(sale_month, '00')) as sale_month,
    total_quantity,
    total_revenue,
    prev_month_revenue,
    
    -- Month-over-Month Growth
    CASE 
        WHEN prev_month_revenue > 0 THEN 
            ROUND(((total_revenue - prev_month_revenue) / prev_month_revenue) * 100, 2)
        ELSE NULL 
    END as mom_growth_percentage,
    
    -- Year-over-Year Growth
    CASE 
        WHEN same_month_last_year_revenue > 0 THEN 
            ROUND(((total_revenue - same_month_last_year_revenue) / same_month_last_year_revenue) * 100, 2)
        ELSE NULL 
    END as yoy_growth_percentage,
    
    -- Growth classification
    CASE 
        WHEN prev_month_revenue > 0 AND ((total_revenue - prev_month_revenue) / prev_month_revenue) > 0.1 
            THEN 'High Growth'
        WHEN prev_month_revenue > 0 AND ((total_revenue - prev_month_revenue) / prev_month_revenue) > 0 
            THEN 'Positive Growth'
        WHEN prev_month_revenue > 0 AND ((total_revenue - prev_month_revenue) / prev_month_revenue) < 0 
            THEN 'Declining'
        ELSE 'No Previous Data'
    END as growth_status
    
FROM ProductGrowth
WHERE prev_month_revenue IS NOT NULL  -- Exclude first month for each product
ORDER BY product_name, sale_year, sale_month;

-- =====================================================
-- BONUS: COMPREHENSIVE USER ANALYTICS SUMMARY
-- =====================================================

-- User Analytics Dashboard
WITH UserMetrics AS (
    SELECT 
        COUNT(DISTINCT u.user_id) as total_users,
        COUNT(DISTINCT CASE WHEN u.status = 'active' THEN u.user_id END) as active_users,
        COUNT(DISTINCT CASE WHEN u.status = 'churned' THEN u.user_id END) as churned_users,
        COUNT(DISTINCT CASE WHEN o.order_date >= DATEADD(day, -30, GETDATE()) THEN o.user_id END) as recent_buyers,
        COUNT(DISTINCT CASE WHEN ua.activity_date >= DATEADD(day, -7, GETDATE()) THEN ua.user_id END) as weekly_active_users,
        COUNT(DISTINCT CASE WHEN ua.activity_date >= DATEADD(day, -30, GETDATE()) THEN ua.user_id END) as monthly_active_users
    FROM #Users u
    LEFT JOIN #Orders o ON u.user_id = o.user_id
    LEFT JOIN #User_Activities ua ON u.user_id = ua.user_id
)
SELECT 
    *,
    ROUND((churned_users * 100.0 / NULLIF(total_users, 0)), 2) as churn_rate_percentage,
    ROUND((weekly_active_users * 100.0 / NULLIF(monthly_active_users, 0)), 2) as weekly_retention_rate,
    ROUND((recent_buyers * 100.0 / NULLIF(monthly_active_users, 0)), 2) as purchase_conversion_rate
FROM UserMetrics;

-- =====================================================
-- CLEANUP
-- =====================================================
DROP TABLE #Users;
DROP TABLE #User_Activities;
DROP TABLE #Orders;
DROP TABLE #Order_Items;
DROP TABLE #Product_Sales;

/*
KEY TAKEAWAYS:

1. CHURN ANALYSIS:
   - Multiple definitions: activity, purchase, status-based
   - Consider business context when defining churn
   - Track different time periods (30, 60, 90 days)

2. USER ACTIVITY METRICS:
   - Running totals show cumulative engagement
   - Moving averages smooth out daily fluctuations
   - 7-day windows are common for user behavior analysis

3. PRODUCT ANALYTICS:
   - Item combinations reveal cross-selling opportunities
   - Consecutive purchases indicate customer loyalty
   - Month-over-month growth tracks product performance

4. PERFORMANCE TIPS:
   - Index on user_id, date columns
   - Use appropriate date ranges to limit data
   - Consider partitioning for large datasets
   - Window functions are powerful for analytics
*/
