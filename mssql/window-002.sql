USE TestData;
GO

select * from sales

-- Example 1: ROW_NUMBER() — Top sale per department
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY department ORDER BY amount DESC) AS rn
    FROM sales
) t
WHERE rn > 1;

-- Example 2: RANK() — Rank sales per department
SELECT *,
       RANK() OVER (PARTITION BY department ORDER BY amount DESC) AS rnk
FROM sales;

-- Example 3: DENSE_RANK() — Dense rank per department
SELECT *,
       DENSE_RANK() OVER (PARTITION BY department ORDER BY amount DESC) AS drnk
FROM sales;

-- Example 4: SUM() OVER() — Running total of sales
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


