-- ================================================================================
-- SECOND HIGHEST SALARY - Multiple Approaches with Examples and Reasoning
-- ================================================================================

-- Sample Employee Table Structure
-- CREATE TABLE employees (
--     emp_id INT PRIMARY KEY,
--     emp_name VARCHAR(100),
--     department VARCHAR(50),
--     salary DECIMAL(10,2)
-- );

-- Sample Data
-- INSERT INTO employees VALUES
-- (1, 'John Smith', 'IT', 75000.00),
-- (2, 'Jane Doe', 'HR', 65000.00),
-- (3, 'Bob Johnson', 'IT', 85000.00),
-- (4, 'Alice Brown', 'Finance', 70000.00),
-- (5, 'Charlie Wilson', 'IT', 95000.00),
-- (6, 'Diana Miller', 'HR', 60000.00),
-- (7, 'Eve Davis', 'Finance', 80000.00),
-- (8, 'Frank Thompson', 'IT', 90000.00);

-- Expected Result: 90000.00 (Frank Thompson's salary)
-- Salary ranking: 95000 (1st), 90000 (2nd), 85000 (3rd), 80000 (4th)...

-- ================================================================================
-- METHOD 1: Using LIMIT/TOP with ORDER BY and Subquery (Most Common)
-- ================================================================================

-- SQL Server / T-SQL Version
-- Reasoning: Order salaries descending, skip first (highest), take next one
SELECT TOP 1
    salary as second_highest_salary
FROM (
    SELECT DISTINCT TOP 2
        salary
    FROM employees
    ORDER BY salary DESC
) as top_two
ORDER BY salary ASC;

-- Alternative SQL Server approach
SELECT MAX(salary) as second_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary)
FROM employees);

-- MySQL/PostgreSQL Version
-- SELECT salary as second_highest_salary
-- FROM employees
-- ORDER BY salary DESC
-- LIMIT 1 OFFSET 1;

-- ================================================================================
-- METHOD 2: Using Window Functions (ROW_NUMBER) - Modern Approach
-- ================================================================================

-- Reasoning: Assign row numbers based on salary rank, then filter for rank 2
-- Handles duplicates by treating them as separate ranks
SELECT salary as second_highest_salary
FROM (
    SELECT salary,
        ROW_NUMBER() OVER (ORDER BY salary DESC) as rn
    FROM employees
) ranked
WHERE rn = 2;

-- ================================================================================
-- METHOD 3: Using Window Functions (DENSE_RANK) - Best for Duplicate Handling
-- ================================================================================

-- Reasoning: DENSE_RANK handles duplicate salaries properly
-- If two people have the highest salary, the next unique salary gets rank 2
SELECT DISTINCT salary as second_highest_salary
FROM (
    SELECT salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank
    FROM employees
) ranked
WHERE dense_rank = 2;

-- ================================================================================
-- METHOD 4: Using Correlated Subquery
-- ================================================================================

-- Reasoning: Find salary where exactly one other salary is higher
-- More complex but works across most SQL dialects
SELECT DISTINCT salary as second_highest_salary
FROM employees e1
WHERE 1 = (
    SELECT COUNT(DISTINCT salary)
FROM employees e2
WHERE e2.salary > e1.salary
);

-- ================================================================================
-- METHOD 5: Using Common Table Expression (CTE) - Clean and Readable
-- ================================================================================

-- Reasoning: CTE makes the query more readable and maintainable
-- Separates the ranking logic from the final selection
WITH
    SalaryRanks
    AS
    (
        SELECT salary,
            DENSE_RANK() OVER (ORDER BY salary DESC) as salary_rank
        FROM employees
    )
SELECT DISTINCT salary as second_highest_salary
FROM SalaryRanks
WHERE salary_rank = 2;

-- ================================================================================
-- METHOD 6: Using Self-Join
-- ================================================================================

-- Reasoning: Join table with itself to find relationships between salaries
-- Less efficient but demonstrates SQL join concepts
SELECT DISTINCT e1.salary as second_highest_salary
FROM employees e1
    JOIN employees e2 ON e2.salary > e1.salary
GROUP BY e1.salary
HAVING COUNT(DISTINCT e2.salary) = 1;

-- ================================================================================
-- METHOD 7: For Getting Nth Highest Salary (Generalized Solution)
-- ================================================================================

-- Get 3rd highest salary (change @n to desired position)
DECLARE @n INT = 3;

WITH
    SalaryRanks
    AS
    (
        SELECT salary,
            DENSE_RANK() OVER (ORDER BY salary DESC) as salary_rank
        FROM employees
    )
SELECT DISTINCT salary as nth_highest_salary
FROM SalaryRanks
WHERE salary_rank = @n;

-- ================================================================================
-- EDGE CASES AND CONSIDERATIONS
-- ================================================================================

-- 1. What if there are duplicate salaries?
-- Example: Two employees with 95000 salary
-- - ROW_NUMBER(): Treats duplicates as separate (arbitrary ordering)
-- - DENSE_RANK(): Groups duplicates together (preferred for this use case)

-- 2. What if there's no second highest salary?
-- (Only one unique salary in table)
-- Most queries will return NULL or no rows

-- 3. Handling NULL salaries
SELECT DISTINCT salary as second_highest_salary
FROM (
    SELECT salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank
    FROM employees
    WHERE salary IS NOT NULL  -- Exclude NULL salaries
) ranked
WHERE dense_rank = 2;

-- ================================================================================
-- PERFORMANCE CONSIDERATIONS
-- ================================================================================

-- 1. Index on salary column improves ORDER BY performance
-- CREATE INDEX IX_employees_salary ON employees(salary);

-- 2. For large tables, LIMIT/TOP approaches are often faster
-- 3. Window functions are more readable but may be slower on very large datasets
-- 4. Correlated subqueries are generally the slowest option

-- ================================================================================
-- DIFFERENT SQL DIALECTS SYNTAX
-- ================================================================================

-- Oracle
