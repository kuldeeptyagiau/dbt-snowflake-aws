-- =========================================
-- SQL Server JOIN Types Explained with Examples
-- =========================================

-- Let's create sample tables to demonstrate different JOIN types
-- First, create two related tables: employees and departments


USE TestData;
GO -- GO is a batch separator used in T-SQL

-- Create departments table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

-- Create employees table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT, -- Foreign key to departments
    salary DECIMAL(10,2)
);

-- Insert sample data into departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(1, 'Engineering', 'San Francisco'),
(2, 'Marketing', 'New York'),
(3, 'Sales', 'Chicago'),
(4, 'HR', 'Los Angeles');

-- Insert sample data into employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(101, 'John Smith', 1, 75000),
(102, 'Jane Doe', 1, 80000),
(103, 'Mike Johnson', 2, 65000),
(104, 'Sarah Wilson', 3, 70000),
(105, 'Bob Brown', NULL, 60000),  -- Employee without department
(106, 'Alice Davis', 5, 85000);   -- Employee with non-existent department

-- =========================================
-- 1. INNER JOIN
-- =========================================
-- Returns only records that have matching values in both tables
-- Only shows employees who have a valid department assigned

SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_id,
    d.dept_name,
    d.dept_id,
    d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Note: If you just write JOIN without specifying INNER, it defaults to INNER JOIN.
-- Result: Only employees with valid dept_id (101, 102, 103, 104)
-- Bob Brown (NULL dept_id) and Alice Davis (invalid dept_id 5) are excluded

-- =========================================
-- 2. LEFT JOIN (LEFT OUTER JOIN)
-- =========================================
-- Returns ALL records from the left table (employees)
-- and matching records from the right table (departments)
-- If no match, NULL values for right table columns

SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
     d.dept_id,
    d.location
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- Result: ALL employees are shown (101-106)
-- Bob Brown shows NULL for dept_name and location
-- Alice Davis shows NULL for dept_name and location


-- Performing right join by moving departments to left instead of doing RIGHT JOIN
SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.dept_id,
    d.location
FROM departments d
LEFT JOIN   employees e ON e.dept_id = d.dept_id;

-- Result: ALL departments are shown (1-4)
-- dept1 is reapeated as it got two employee in employee table


-- =========================================
-- 3. RIGHT JOIN (RIGHT OUTER JOIN)
-- =========================================
-- Returns ALL records from the right table (departments)
-- and matching records from the left table (employees)
-- If no match, NULL values for left table columns

SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.dept_id,
    d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Result: ALL departments are shown (1-4)
-- HR department shows NULL for employee details (no employees in HR)
-- Bob Brown and Alice Davis are excluded (no valid department match)

-- =========================================
-- 4. FULL OUTER JOIN
-- =========================================
-- Returns ALL records from both tables
-- Shows NULLs where there's no match in either direction

SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.dept_id,
    d.location
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;
-- where e.emp_id is null or d.dept_id is null

-- Result: Shows everything - all employees AND all departments
-- Bob Brown: shows employee info but NULL for department
-- Alice Davis: shows employee info but NULL for department
-- HR department: shows department info but NULL for employee

-- =========================================
-- VISUAL REPRESENTATION OF RESULTS
-- =========================================

/*
Sample Data:
Employees:        Departments:
101 - John (1)    1 - Engineering
102 - Jane (1)    2 - Marketing  
103 - Mike (2)    3 - Sales
104 - Sarah (3)   4 - HR
105 - Bob (NULL)
106 - Alice (5)

INNER JOIN Results:
- John + Engineering
- Jane + Engineering  
- Mike + Marketing
- Sarah + Sales
(Only matching records)

LEFT JOIN Results:
- John + Engineering
- Jane + Engineering
- Mike + Marketing
- Sarah + Sales
- Bob + NULL
- Alice + NULL
(All employees, with or without department)

RIGHT JOIN Results:
- John + Engineering
- Jane + Engineering
- Mike + Marketing
- Sarah + Sales
- NULL + HR
(All departments, with or without employees)

FULL OUTER JOIN Results:
- John + Engineering
- Jane + Engineering
- Mike + Marketing
- Sarah + Sales
- Bob + NULL
- Alice + NULL
- NULL + HR
(Everything from both tables)
*/

-- =========================================
-- PRACTICAL USE CASES
-- =========================================

-- 1. INNER JOIN - When you need only complete records
-- Example: Generate payroll report for employees with valid departments
SELECT 
    e.emp_name,
    d.dept_name,
    e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 2. LEFT JOIN - When you need all records from main table
-- Example: All employees including those without department assignment
SELECT 
    e.emp_name,
    COALESCE(d.dept_name, 'Unassigned') as department,
    COALESCE(d.dept_name, null) as dep1,
    e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id


-- 2. LEFT JOIN with filter Null check
-- Example: ONLY employees whose dept_id did NOT match anything in departments table
SELECT 
    e.emp_name,
    COALESCE(d.dept_name, 'Unassigned') as department,
    COALESCE(d.dept_name, null) as dep1,
    e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
where d.dept_id is null

-- 2. RIGHT JOIN with filter Null check
-- Example: ONLY departments that DO NOT have any employees assigned
SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.dept_id,
    d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
where e.dept_id is null

-- 3. FULL OUTER JOIN - When you need to see gaps in your data
-- Example: Data quality check to find employees without departments 
-- and departments without employees
SELECT 
    -- e.emp_id,
    CASE 
        WHEN e.emp_id IS NULL THEN 'NO EMPLOYEES'
        ELSE e.emp_name 
    END as employee_status,
    -- d.dept_id,
    CASE 
        WHEN d.dept_id IS NULL THEN 'NO DEPARTMENT'
        ELSE d.dept_name 
    END as department_status
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

-- =========================================
-- KEY DIFFERENCES SUMMARY
-- =========================================

/*
JOIN TYPE        | RETURNS                           | USE CASE
----------------|-----------------------------------|------------------
INNER JOIN      | Only matching records             | Complete data only
LEFT JOIN       | All from left + matches from right| Keep all main records
RIGHT JOIN      | All from right + matches from left| Keep all lookup records  
FULL OUTER JOIN | All records from both tables      | See all data & gaps

Performance Note:
- INNER JOIN is typically fastest
- LEFT JOIN is common for optional relationships
- FULL OUTER JOIN can be slowest on large datasets
*/

-- Clean up (optional - uncomment to remove test tables)
-- DROP TABLE employees;
-- DROP TABLE departments;
