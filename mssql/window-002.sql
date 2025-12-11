USE TestData;
GO

select * from sales

select null
-- This is now the de-facto standard for top-N-per-group.
WITH RankedOrders AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY department
               ORDER BY amount DESC
           ) AS rn
    FROM sales
)
SELECT *
FROM RankedOrders
WHERE rn <= 3;

SELECT DATEADD(DAY, -1, GETDATE()) , DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
go

-- Example 1: ROW_NUMBER() — Top sale per department

SET SHOWPLAN_ALL ON;
GO
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY department ORDER BY amount DESC) AS rn
    FROM sales
) t
WHERE rn > 1;

SET SHOWPLAN_ALL OFF;
GO

-- Example 2: RANK() — Rank sales per department
SET STATISTICS PROFILE ON;
SELECT *,
       RANK() OVER (PARTITION BY department ORDER BY amount DESC) AS rnk
FROM sales;
SET STATISTICS PROFILE OFF;

-- Example 3: DENSE_RANK() — Dense rank per department
SELECT *,
       DENSE_RANK() OVER (PARTITION BY department ORDER BY amount DESC) AS drnk
FROM sales;

-- Example 4: SUM() OVER() — Running total of sales

select sum(amount) from sales
-- Using SUM as window function (with the OVER clause), does not reduce the no of records. Please note it’s not mandatory to use ORDER BY or PARTITION BY inside the OVER clause
select sum(amount) over ()from sales

SELECT order_id,
       amount,
       SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM sales;

-- Example 5: LAG() and LEAD() — Previous and next order amounts
SELECT order_id,
       amount,
       LAG(amount) OVER (ORDER BY order_date) AS prev_amount,
       LEAD(amount) OVER (ORDER BY order_date) AS next_amount
FROM sales;

-- Example 6: FIRST_VALUE() and LAST_VALUE() per customer
SELECT customer_id,
       amount,
       FIRST_VALUE(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS first_order,
       LAST_VALUE(amount) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS last_order
FROM sales;


-- Note: In SQL Server, LAST_VALUE requires the ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING frame to get the last value across the partition.

-- Example 7: NTILE() — Divide into 2 buckets
SELECT customer_id,
       amount,
       NTILE(2) OVER (ORDER BY amount) AS half
FROM sales;

-- Example 8: Moving average (3-day window)
SELECT order_date,
       amount,
       AVG(amount) OVER (
           ORDER BY order_date
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS moving_avg_3
FROM sales;


