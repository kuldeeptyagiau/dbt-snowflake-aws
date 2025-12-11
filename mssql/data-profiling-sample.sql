-- =============================================
-- Data Profiling Using SQL Server
-- =============================================
-- This script demonstrates various data profiling techniques
-- to identify data quality issues including:
-- 1. Missing values
-- 2. Null percentages  
-- 3. Duplicate records
-- 4. Invalid values
-- 5. Outliers
-- 6. Incorrect formats
-- 7. Referential integrity issues

-- Use TestData database (create it first if it doesn't exist)
USE TestData;
GO

-- =============================================
-- 0. CLEANUP EXISTING TABLES AND CONSTRAINTS
-- =============================================

-- Drop tables if they exist (in correct order due to dependencies)
IF OBJECT_ID('OrderDetails_dp', 'U') IS NOT NULL 
    DROP TABLE OrderDetails_dp;
IF OBJECT_ID('Orders_dp', 'U') IS NOT NULL 
    DROP TABLE Orders_dp;
IF OBJECT_ID('Products_dp', 'U') IS NOT NULL 
    DROP TABLE Products_dp;
IF OBJECT_ID('Customers_dp', 'U') IS NOT NULL 
    DROP TABLE Customers_dp;

-- =============================================
-- 1. CREATE SAMPLE TABLES WITH DATA QUALITY ISSUES
-- =============================================

-- Customers_dp table with various data quality issues
CREATE TABLE Customers_dp (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    DateOfBirth DATE,
    Gender CHAR(1),
    Country NVARCHAR(50),
    City NVARCHAR(50),
    PostalCode NVARCHAR(20),
    RegistrationDate DATETIME,
    IsActive BIT
);

-- Orders table with referential integrity issues
CREATE TABLE Orders_dp (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    ShipDate DATE,
    TotalAmount DECIMAL(10,2),
    OrderStatus NVARCHAR(20),
    SalesRepID INT
    -- Note: Foreign key constraint removed to allow invalid data for demo purposes
    -- FOREIGN KEY (CustomerID) REFERENCES Customers_dp(CustomerID)
);

-- Products table
CREATE TABLE Products_dp (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100),
    Category NVARCHAR(50),
    UnitPrice DECIMAL(10,2),
    UnitsInStock INT,
    Discontinued BIT
);

-- OrderDetails table
CREATE TABLE OrderDetails_dp (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    Discount DECIMAL(3,2)
    -- Note: Foreign key constraints removed to allow invalid data for demo purposes
    -- FOREIGN KEY (OrderID) REFERENCES Orders_dp(OrderID),
    -- FOREIGN KEY (ProductID) REFERENCES Products_dp(ProductID)
);

-- =============================================
-- 2. INSERT SAMPLE DATA WITH QUALITY ISSUES
-- =============================================

-- Insert Customers_dp with various data quality issues
INSERT INTO Customers_dp (FirstName, LastName, Email, Phone, DateOfBirth, Gender, Country, City, PostalCode, RegistrationDate, IsActive)
VALUES 
    -- Valid records
    ('John', 'Smith', 'john.smith@email.com', '+1-555-0101', '1985-03-15', 'M', 'USA', 'New York', '10001', '2023-01-15', 1),
    ('Jane', 'Johnson', 'jane.johnson@email.com', '+1-555-0102', '1990-07-22', 'F', 'USA', 'Los Angeles', '90210', '2023-02-20', 1),
    ('Michael', 'Brown', 'michael.brown@email.com', '+1-555-0103', '1988-11-08', 'M', 'USA', 'Chicago', '60601', '2023-03-10', 1),
    
    -- Records with missing/null values
    ('Sarah', NULL, 'sarah.davis@email.com', '+1-555-0104', '1992-05-18', 'F', 'USA', 'Houston', '77001', '2023-04-05', 1),
    ('Robert', 'Wilson', NULL, '+1-555-0105', '1987-09-12', 'M', 'USA', 'Phoenix', '85001', '2023-05-12', 1),
    ('Emily', 'Taylor', 'emily.taylor@email.com', NULL, '1991-12-03', 'F', 'USA', 'Philadelphia', '19101', '2023-06-08', 1),
    (NULL, 'Anderson', 'anderson@email.com', '+1-555-0107', '1989-02-28', 'M', 'USA', 'San Antonio', '78201', '2023-07-15', 1),
    
    -- Duplicate records
    ('John', 'Smith', 'john.smith@email.com', '+1-555-0101', '1985-03-15', 'M', 'USA', 'New York', '10001', '2023-01-15', 1),
    ('John', 'Smith', 'johnsmith@gmail.com', '+1-555-0108', '1985-03-15', 'M', 'USA', 'New York', '10001', '2023-08-20', 1),
    
    -- Invalid values
    ('David', 'Martinez', 'invalid-email', '+1-555-0109', '1986-06-25', 'X', 'USA', 'San Diego', '92101', '2023-09-10', 1),
    ('Lisa', 'Garcia', 'lisa.garcia@email.com', '555-INVALID', '1993-10-14', 'F', 'USA', 'Dallas', '75201', '2023-10-05', 1),
    ('James', 'Rodriguez', 'james.rodriguez@email.com', '+1-555-0111', '2050-01-01', 'M', 'USA', 'Austin', '78701', '2023-11-12', 1), -- Future birth date
    
    -- Outliers
    ('Ancient', 'Person', 'ancient@email.com', '+1-555-0112', '1900-01-01', 'M', 'USA', 'Boston', '02101', '2023-12-01', 1), -- Very old
    ('Mary', 'Johnson', 'mary.j@email.com', '+1-555-0113', '1995-04-20', 'F', 'Unknown Country', 'Unknown City', 'UNKNOWN', '2023-12-15', 1),
    
    -- Formatting issues
    ('chris', 'lee', 'CHRIS.LEE@EMAIL.COM', '15550114', '1994-08-17', 'f', 'usa', 'seattle', '98101', '2023-12-20', 1), -- Case issues
    ('Jennifer', 'White', 'jennifer.white@email.com', '+1 555 0115', '1996-03-11', 'F', 'USA', 'Denver', '80201', '2023-12-25', 1); -- Phone format variation

-- Insert Products
INSERT INTO Products_dp (ProductName, Category, UnitPrice, UnitsInStock, Discontinued)
VALUES 
    ('Laptop Pro', 'Electronics', 1299.99, 50, 0),
    ('Wireless Mouse', 'Electronics', 29.99, 100, 0),
    ('Office Chair', 'Furniture', 299.99, 25, 0),
    ('Standing Desk', 'Furniture', 599.99, 15, 0),
    ('Coffee Mug', 'Accessories', 9.99, 200, 0),
    ('Notebook', 'Stationery', 4.99, 500, 0),
    ('Old Product', 'Obsolete', 99.99, 0, 1), -- Discontinued
    ('Expensive Item', 'Luxury', 9999.99, 1, 0), -- Outlier price
    (NULL, 'Category', 19.99, 10, 0), -- Missing product name
    ('Duplicate Item', 'Test', 15.99, 20, 0),
    ('Duplicate Item', 'Test', 15.99, 20, 0); -- Exact duplicate

-- Insert Orders (some with referential integrity issues)
INSERT INTO Orders_dp (CustomerID, OrderDate, ShipDate, TotalAmount, OrderStatus, SalesRepID)
VALUES 
    (1, '2023-12-01', '2023-12-03', 1329.98, 'Shipped', 101),
    (2, '2023-12-02', '2023-12-05', 599.99, 'Delivered', 102),
    (3, '2023-12-03', NULL, 39.98, 'Processing', 103), -- Missing ship date
    (1, '2023-12-04', '2023-12-06', 309.98, 'Shipped', 101), -- Valid CustomerID 1
    (99, '2023-12-05', '2023-12-07', 199.99, 'Shipped', 104), -- Invalid CustomerID (referential integrity issue)
    (2, '2023-12-06', '2023-12-08', 29.99, 'Delivered', NULL), -- Missing SalesRepID
    (1, '2023-12-07', '2023-12-02', 49.99, 'Invalid Status', 105), -- Ship date before order date
    (2, '2023-12-08', '2023-12-10', -50.00, 'Shipped', 102), -- Negative amount
    (3, '2023-12-09', '2023-12-11', 999999.99, 'Delivered', 103); -- Outlier amount

-- Insert OrderDetails
INSERT INTO OrderDetails_dp (OrderID, ProductID, Quantity, UnitPrice, Discount)
VALUES 
    (1, 1, 1, 1299.99, 0.00),
    (1, 2, 1, 29.99, 0.00),
    (2, 4, 1, 599.99, 0.00),
    (3, 2, 1, 29.99, 0.10),
    (3, 5, 1, 9.99, 0.00),
    (4, 3, 1, 299.99, 0.05),
    (4, 5, 1, 9.99, 0.00),
    (5, 2, 1, 29.99, 0.00), -- Valid OrderID 5
    (6, 6, 10, 4.99, 0.00), -- Valid OrderID 6
    (7, 1, -1, 1299.99, 0.00), -- Negative quantity
    (8, 8, 1, 9999.99, 0.00), -- Valid OrderID 8
    (99, 1, 1, 1299.99, 0.00); -- Invalid OrderID (referential integrity issue)

-- =============================================
-- 3. DATA PROFILING QUERIES
-- =============================================

PRINT '=============================================';
PRINT 'DATA PROFILING ANALYSIS RESULTS';
PRINT '=============================================';
PRINT '';

-- =============================================
-- 3.1. MISSING VALUES AND NULL PERCENTAGES
-- =============================================
PRINT '1. MISSING VALUES AND NULL PERCENTAGES';
PRINT '----------------------------------------';

select * from Customers_dp

select (count(*) - count(FirstName)) as no_of_null from Customers_dp 
-- Customers_dp table null analysis
SELECT 
    'Customers_dp' AS TableName,
    'FirstName' AS ColumnName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END) AS NullCount,
    CAST(SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS NullPercentage
FROM Customers_dp

UNION ALL

SELECT 
    'Customers_dp', 'LastName',
    COUNT(*), 
    SUM(CASE WHEN LastName IS NULL THEN 1 ELSE 0 END),
    CAST(SUM(CASE WHEN LastName IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
FROM Customers_dp

UNION ALL

SELECT 
    'Customers_dp', 'Email',
    COUNT(*), 
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END),
    CAST(SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
FROM Customers_dp

UNION ALL

SELECT 
    'Customers_dp', 'Phone',
    COUNT(*), 
    SUM(CASE WHEN Phone IS NULL THEN 1 ELSE 0 END),
    CAST(SUM(CASE WHEN Phone IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
FROM Customers_dp

ORDER BY NullPercentage DESC;

PRINT '';

-- =============================================
-- 3.2. DUPLICATE RECORDS ANALYSIS
-- =============================================
PRINT '2. DUPLICATE RECORDS ANALYSIS';
PRINT '------------------------------';

-- Find potential duplicate customers_dp (same name and birth date)
SELECT 
    FirstName, LastName, DateOfBirth, COUNT(*) AS DuplicateCount
FROM Customers_dp
WHERE FirstName IS NOT NULL AND LastName IS NOT NULL AND DateOfBirth IS NOT NULL
GROUP BY FirstName, LastName, DateOfBirth
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;

PRINT '';

-- Find exact duplicate products
SELECT 
    ProductName, Category, UnitPrice, COUNT(*) AS DuplicateCount
FROM Products_dp
WHERE ProductName IS NOT NULL
GROUP BY ProductName, Category, UnitPrice
HAVING COUNT(*) > 1;

PRINT '';

-- =============================================
-- 3.3. INVALID VALUES ANALYSIS
-- =============================================
PRINT '3. INVALID VALUES ANALYSIS';
PRINT '---------------------------';

-- Invalid email formats
SELECT 
    CustomerID, FirstName, LastName, Email
FROM Customers_dp
WHERE Email IS NOT NULL 
    AND Email NOT LIKE '%@%.%'
    AND Email <> '';

PRINT '';

-- Invalid gender values
SELECT 
    CustomerID, FirstName, LastName, Gender
FROM Customers_dp
WHERE Gender NOT IN ('M', 'F') OR Gender IS NULL;

PRINT '';

-- Invalid phone formats (should start with + and contain digits)
SELECT 
    CustomerID, FirstName, LastName, Phone
FROM Customers_dp
WHERE Phone IS NOT NULL 
    AND (Phone NOT LIKE '+%' OR Phone LIKE '%[^0-9+\-\s]%');

PRINT '';

-- =============================================
-- 3.4. OUTLIERS ANALYSIS
-- =============================================
PRINT '4. OUTLIERS ANALYSIS';
PRINT '--------------------';

-- Age outliers (customers_dp with unusual ages)
SELECT 
    CustomerID,
    FirstName,
    LastName,
    DateOfBirth,
    DATEDIFF(YEAR, DateOfBirth, GETDATE()) AS Age,
    CASE 
        WHEN DATEDIFF(YEAR, DateOfBirth, GETDATE()) > 100 THEN 'Too Old'
        WHEN DATEDIFF(YEAR, DateOfBirth, GETDATE()) < 18 THEN 'Too Young'
        WHEN DateOfBirth > GETDATE() THEN 'Future Date'
        ELSE 'Normal'
    END AS AgeCategory
FROM Customers_dp
WHERE DateOfBirth IS NOT NULL
    AND (DATEDIFF(YEAR, DateOfBirth, GETDATE()) > 100 
         OR DATEDIFF(YEAR, DateOfBirth, GETDATE()) < 18
         OR DateOfBirth > GETDATE());

PRINT '';

-- Price outliers in products
SELECT 
    ProductID,
    ProductName,
    UnitPrice,
    CASE 
        WHEN UnitPrice > 5000 THEN 'Very Expensive'
        WHEN UnitPrice < 1 THEN 'Very Cheap'
        ELSE 'Normal'
    END AS PriceCategory
FROM Products_dp
WHERE UnitPrice > 5000 OR UnitPrice < 1;

PRINT '';

-- Order amount outliers
SELECT 
    OrderID,
    CustomerID,
    TotalAmount,
    CASE 
        WHEN TotalAmount > 10000 THEN 'Very High'
        WHEN TotalAmount < 0 THEN 'Negative Amount'
        ELSE 'Normal'
    END AS AmountCategory
FROM Orders_dp
WHERE TotalAmount > 10000 OR TotalAmount < 0;

PRINT '';

-- =============================================
-- 3.5. INCORRECT FORMATS ANALYSIS
-- =============================================
PRINT '5. INCORRECT FORMATS ANALYSIS';
PRINT '------------------------------';

-- Case consistency issues
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    Country,
    City,
    CASE 
        WHEN FirstName COLLATE SQL_Latin1_General_CP1_CS_AS <> UPPER(LEFT(FirstName, 1)) + LOWER(SUBSTRING(FirstName, 2, LEN(FirstName)))
             AND FirstName IS NOT NULL THEN 'FirstName Case Issue'
        WHEN LastName COLLATE SQL_Latin1_General_CP1_CS_AS <> UPPER(LEFT(LastName, 1)) + LOWER(SUBSTRING(LastName, 2, LEN(LastName)))
             AND LastName IS NOT NULL THEN 'LastName Case Issue'
        WHEN Email <> LOWER(Email) AND Email IS NOT NULL THEN 'Email Case Issue'
        WHEN Country <> UPPER(Country) AND Country IS NOT NULL THEN 'Country Case Issue'
        ELSE 'No Issues'
    END AS FormatIssue
FROM Customers_dp
WHERE (FirstName IS NOT NULL AND FirstName COLLATE SQL_Latin1_General_CP1_CS_AS <> UPPER(LEFT(FirstName, 1)) + LOWER(SUBSTRING(FirstName, 2, LEN(FirstName))))
   OR (LastName IS NOT NULL AND LastName COLLATE SQL_Latin1_General_CP1_CS_AS <> UPPER(LEFT(LastName, 1)) + LOWER(SUBSTRING(LastName, 2, LEN(LastName))))
   OR (Email IS NOT NULL AND Email <> LOWER(Email))
   OR (Country IS NOT NULL AND Country <> UPPER(Country));

PRINT '';

-- =============================================
-- 3.6. REFERENTIAL INTEGRITY ISSUES
-- =============================================
PRINT '6. REFERENTIAL INTEGRITY ISSUES';
PRINT '--------------------------------';

-- Orders with invalid CustomerID
SELECT 
    o.OrderID,
    o.CustomerID,
    o.OrderDate,
    o.TotalAmount,
    'Missing Customer' AS Issue
FROM Orders_dp o
LEFT JOIN Customers_dp c ON o.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

PRINT '';

-- OrderDetails with invalid OrderID
SELECT 
    od.OrderDetailID,
    od.OrderID,
    od.ProductID,
    od.Quantity,
    'Missing Order' AS Issue
FROM OrderDetails_dp od
LEFT JOIN Orders_dp o ON od.OrderID = o.OrderID
WHERE o.OrderID IS NULL;

PRINT '';

-- OrderDetails with invalid ProductID
SELECT 
    od.OrderDetailID,
    od.OrderID,
    od.ProductID,
    od.Quantity,
    'Missing Product' AS Issue
FROM OrderDetails_dp od
LEFT JOIN Products_dp p ON od.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

PRINT '';

-- =============================================
-- 3.7. BUSINESS LOGIC VIOLATIONS
-- =============================================
PRINT '7. BUSINESS LOGIC VIOLATIONS';
PRINT '-----------------------------';

-- Orders where ship date is before order date
SELECT 
    OrderID,
    CustomerID,
    OrderDate,
    ShipDate,
    'Ship Date Before Order Date' AS Issue
FROM Orders_dp
WHERE ShipDate < OrderDate;

PRINT '';

-- Negative quantities in order details
SELECT 
    OrderDetailID,
    OrderID,
    ProductID,
    Quantity,
    'Negative Quantity' AS Issue
FROM OrderDetails_dp
WHERE Quantity < 0;

PRINT '';

-- =============================================
-- 3.8. DATA COMPLETENESS SUMMARY
-- =============================================
PRINT '8. DATA COMPLETENESS SUMMARY';
PRINT '-----------------------------';

SELECT 
    TableName,
    TotalRecords,
    CompleteRecords,
    IncompleteRecords,
    CAST(CompleteRecords * 100.0 / TotalRecords AS DECIMAL(5,2)) AS CompletenessPercentage
FROM (
    SELECT 
        'Customers' AS TableName,
        COUNT(*) AS TotalRecords,
        SUM(CASE WHEN FirstName IS NOT NULL AND LastName IS NOT NULL AND Email IS NOT NULL 
                  AND Phone IS NOT NULL AND DateOfBirth IS NOT NULL THEN 1 ELSE 0 END) AS CompleteRecords,
        SUM(CASE WHEN FirstName IS NULL OR LastName IS NULL OR Email IS NULL 
                  OR Phone IS NULL OR DateOfBirth IS NULL THEN 1 ELSE 0 END) AS IncompleteRecords
    FROM Customers_dp
    
    UNION ALL
    
    SELECT 
        'Orders',
        COUNT(*),
        SUM(CASE WHEN CustomerID IS NOT NULL AND OrderDate IS NOT NULL AND ShipDate IS NOT NULL 
                  AND TotalAmount IS NOT NULL AND SalesRepID IS NOT NULL THEN 1 ELSE 0 END),
        SUM(CASE WHEN CustomerID IS NULL OR OrderDate IS NULL OR ShipDate IS NULL 
                  OR TotalAmount IS NULL OR SalesRepID IS NULL THEN 1 ELSE 0 END)
    FROM Orders_dp
    
    UNION ALL
    
    SELECT 
        'Products',
        COUNT(*),
        SUM(CASE WHEN ProductName IS NOT NULL AND Category IS NOT NULL AND UnitPrice IS NOT NULL 
                  AND UnitsInStock IS NOT NULL THEN 1 ELSE 0 END),
        SUM(CASE WHEN ProductName IS NULL OR Category IS NULL OR UnitPrice IS NULL 
                  OR UnitsInStock IS NULL THEN 1 ELSE 0 END)
    FROM Products_dp
) AS Summary
ORDER BY CompletenessPercentage;

PRINT '';

-- =============================================
-- 3.9. ADVANCED PROFILING - STATISTICAL ANALYSIS
-- =============================================
PRINT '9. STATISTICAL ANALYSIS';
PRINT '------------------------';

-- Numeric column statistics
SELECT 
    'Order Amounts' AS MetricType,
    COUNT(*) AS RecordCount,
    MIN(TotalAmount) AS MinValue,
    MAX(TotalAmount) AS MaxValue,
    AVG(TotalAmount) AS AvgValue,
    STDEV(TotalAmount) AS StandardDeviation,
    (SELECT TotalAmount FROM (
        SELECT TotalAmount, ROW_NUMBER() OVER (ORDER BY TotalAmount) AS rn,
               COUNT(*) OVER() AS cnt
        FROM Orders_dp WHERE TotalAmount IS NOT NULL
    ) AS ranked WHERE rn = (cnt + 1) / 2) AS MedianValue
FROM Orders_dp
WHERE TotalAmount IS NOT NULL

UNION ALL

SELECT 
    'Product Prices',
    COUNT(*),
    MIN(UnitPrice),
    MAX(UnitPrice),
    AVG(UnitPrice),
    STDEV(UnitPrice),
    (SELECT UnitPrice FROM (
        SELECT UnitPrice, ROW_NUMBER() OVER (ORDER BY UnitPrice) AS rn,
               COUNT(*) OVER() AS cnt
        FROM Products_dp WHERE UnitPrice IS NOT NULL
    ) AS ranked WHERE rn = (cnt + 1) / 2)
FROM Products_dp
WHERE UnitPrice IS NOT NULL;


-- # Histogram Query
CREATE TABLE users (
    user_id INT,
    user_name VARCHAR(50),
    age INT
);

INSERT INTO users (user_id, user_name, age)
VALUES
-- Age 0–20
(1, 'John Smith',     19),
(2, 'Jane Doe',       20),

-- Age 21–30
(3, 'Bob Johnson',    26),
(4, 'Alice Brown',    29),

-- Age 31–40
(5, 'Charlie Wilson', 34),
(6, 'Diana Miller',   37),

-- Age 40+
(7, 'Eve Davis',      45),
(8, 'Frank Thompson', 52),

-- Extra outliers for histogram testing
(9, 'Test Young',     0),     -- bad value
(10, 'Test Old',      120);   -- outlier

select * from users

SELECT
    CASE
        WHEN age BETWEEN 0 AND 20 THEN '0-20'
        WHEN age BETWEEN 21 AND 30 THEN '21-30'
        WHEN age BETWEEN 31 AND 40 THEN '31-40'
        ELSE '40+'
    END AS age_group,
    COUNT(*) AS frequency
FROM users
GROUP BY
    CASE
        WHEN age BETWEEN 0 AND 20 THEN '0-20'
        WHEN age BETWEEN 21 AND 30 THEN '21-30'
        WHEN age BETWEEN 31 AND 40 THEN '31-40'
        ELSE '40+'
    END
ORDER BY age_group;

-- cleaner version of code
SELECT age_group, COUNT(*) AS frequency
FROM (
    SELECT 
        CASE
            WHEN age BETWEEN 0 AND 20 THEN '0-20'
            WHEN age BETWEEN 21 AND 30 THEN '21-30'
            WHEN age BETWEEN 31 AND 40 THEN '31-40'
            ELSE '40+'
        END AS age_group
    FROM users
) t
GROUP BY age_group
ORDER BY age_group;




PRINT '';

-- =============================================
-- 3.10. RECOMMENDATIONS FOR DATA QUALITY
-- =============================================
PRINT '10. DATA QUALITY RECOMMENDATIONS';
PRINT '---------------------------------';
PRINT 'Based on the data profiling analysis, here are recommendations:';
PRINT '';
PRINT '1. NULL VALUES:';
PRINT '   - Implement validation to ensure critical fields are not null';
PRINT '   - Consider default values for optional fields';
PRINT '';
PRINT '2. DUPLICATES:';
PRINT '   - Create unique constraints or indexes to prevent duplicates';
PRINT '   - Implement deduplication procedures';
PRINT '';
PRINT '3. INVALID VALUES:';
PRINT '   - Add check constraints for email format validation';
PRINT '   - Implement domain validation for gender, status fields';
PRINT '';
PRINT '4. OUTLIERS:';
PRINT '   - Review age calculations and birth date validations';
PRINT '   - Implement price range validations';
PRINT '';
PRINT '5. REFERENTIAL INTEGRITY:';
PRINT '   - Enable foreign key constraints';
PRINT '   - Implement cascade delete/update rules';
PRINT '';
PRINT '6. BUSINESS LOGIC:';
PRINT '   - Add check constraints for date logic';
PRINT '   - Implement triggers for complex business rules';
PRINT '';

-- =============================================
-- END OF DATA PROFILING SCRIPT
-- =============================================
PRINT 'Data profiling analysis completed!';
