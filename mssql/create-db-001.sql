-- Ensure you are running this in the master database context initially,
-- or just run the CREATE DATABASE line if using SSMS UI.
CREATE DATABASE TestData;
GO -- GO is a batch separator used in T-SQL

USE TestData;
GO

CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    Email VARCHAR(255) NULL,
    SignupDate DATETIME2 -- Use DATETIME2 for better precision in SQL Server
);
GO

-- Step 1: Create the sales table and insert data
-- Create table
CREATE TABLE sales (
    order_id INT PRIMARY KEY,
    customer_id INT,
    department VARCHAR(50),
    order_date DATE,
    amount DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO sales (order_id, customer_id, department, order_date, amount) VALUES
(1, 101, 'Electronics', '2025-12-01', 500),
(2, 102, 'Electronics', '2025-12-02', 700),
(3, 101, 'Books', '2025-12-02', 200),
(4, 103, 'Electronics', '2025-12-03', 700),
(5, 102, 'Books', '2025-12-04', 300),
(6, 101, 'Electronics', '2025-12-05', 400);
