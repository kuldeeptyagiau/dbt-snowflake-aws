# Data Profiling Using SQL Server

## What Is Data Profiling?

Data profiling is the process of examining, analyzing, and understanding the structure, content, and quality of data within a dataset or database. It involves systematically reviewing data to identify patterns, anomalies, and potential issues that could impact data quality and business operations.

## Key Aspects of Data Profiling

### 1. Missing Values
- **Definition**: Fields that contain NULL values or are completely empty
- **Impact**: Can cause errors in calculations, reports, and business logic
- **Detection**: Count NULL values and calculate percentages for each column

### 2. Null Percentages
- **Definition**: The percentage of NULL values in each column
- **Impact**: High null percentages may indicate data collection issues
- **Best Practice**: Establish acceptable null percentage thresholds (e.g., <5%)

### 3. Duplicate Records
- **Definition**: Records that appear multiple times in the dataset
- **Types**: 
  - Exact duplicates (all fields match)
  - Partial duplicates (key fields match)
- **Detection**: Use GROUP BY with HAVING COUNT(*) > 1

### 4. Invalid Values
- **Definition**: Data that doesn't conform to expected formats or business rules
- **Examples**: 
  - Invalid email formats
  - Gender values outside M/F
  - Incorrect phone number formats
- **Detection**: Use pattern matching and domain validation

### 5. Outliers
- **Definition**: Values that are significantly different from the typical range
- **Examples**:
  - Ages over 120 years or negative ages
  - Extremely high or low prices
  - Future dates for historical events
- **Detection**: Use statistical analysis and business rule validation

### 6. Incorrect Formats
- **Definition**: Data that doesn't follow standardized formatting conventions
- **Examples**:
  - Inconsistent case (uppercase/lowercase)
  - Mixed date formats
  - Varying phone number formats
- **Detection**: Use pattern matching and standardization rules

### 7. Referential Integrity Issues
- **Definition**: Foreign key references that don't match primary keys
- **Impact**: Orphaned records that can cause application errors
- **Detection**: LEFT JOIN to identify missing references

## How to Use the Sample Script

### Prerequisites
- SQL Server instance (any version 2012+)
- SQL Server Management Studio (SSMS) or similar SQL client
- Appropriate database permissions (CREATE TABLE, INSERT, SELECT)
- TestData database (create using `create-db-001.sql` if it doesn't exist)

### Running the Script

1. **Create TestData Database**: First run `create-db-001.sql` if the TestData database doesn't exist
2. **Open the Script**: Load `data-profiling-sample.sql` in SSMS
3. **Execute**: Run the entire script (F5 or Execute button)
4. **Review Results**: The script will output detailed analysis results

### Script Structure

The script is organized into several sections:

#### Section 1: Table Creation
- Uses the existing TestData database
- Defines tables: Customers, Orders, Products, OrderDetails
- Includes foreign key relationships

#### Section 2: Sample Data Insertion
- Inserts realistic sample data with intentional quality issues
- Includes examples of all common data quality problems

#### Section 3: Data Profiling Queries
The script performs 10 different types of analysis:

1. **Missing Values and Null Percentages**
   - Calculates null counts and percentages for key columns
   - Identifies columns with high missing data rates

2. **Duplicate Records Analysis**
   - Finds potential duplicate customers
   - Identifies exact duplicate products

3. **Invalid Values Analysis**
   - Checks email format validity
   - Validates gender values
   - Checks phone number formats

4. **Outliers Analysis**
   - Identifies customers with unusual ages
   - Finds products with extreme prices
   - Detects orders with abnormal amounts

5. **Incorrect Formats Analysis**
   - Checks for case consistency issues
   - Identifies formatting problems

6. **Referential Integrity Issues**
   - Finds orders without valid customers
   - Identifies orphaned order details

7. **Business Logic Violations**
   - Checks for illogical date relationships
   - Finds negative quantities

8. **Data Completeness Summary**
   - Provides overall completeness percentage by table
   - Summarizes data quality metrics

9. **Statistical Analysis**
   - Calculates min, max, average, standard deviation
   - Provides median values for numeric columns

10. **Data Quality Recommendations**
    - Provides actionable suggestions for improvement

### Sample Output Interpretation

#### Null Percentage Results
```
TableName  ColumnName  TotalRecords  NullCount  NullPercentage
Customers  Phone       16            2          12.50
Customers  LastName    16            1          6.25
Customers  FirstName   16            1          6.25
Customers  Email       16            1          6.25
```

**Interpretation**: Phone field has the highest null percentage (12.5%), indicating potential data collection issues.

#### Duplicate Analysis Results
```
FirstName  LastName  DateOfBirth  DuplicateCount
John       Smith     1985-03-15   2
```

**Interpretation**: Two customers named "John Smith" with the same birth date exist, indicating potential duplicates.

#### Outlier Detection Results
```
CustomerID  FirstName  Age  AgeCategory
13          Ancient    124  Too Old
12          James      -27  Future Date
```

**Interpretation**: Customer 13 has an unrealistic age, and Customer 12 has a future birth date.

## Best Practices for Data Profiling

### 1. Regular Monitoring
- Schedule data profiling to run regularly (daily/weekly/monthly)
- Set up alerts for quality metric thresholds
- Track trends over time

### 2. Business Context
- Understand business rules and requirements
- Define acceptable quality thresholds
- Prioritize issues based on business impact

### 3. Comprehensive Coverage
- Profile all critical data elements
- Include both source and derived data
- Consider data relationships and dependencies

### 4. Documentation
- Document findings and remediation actions
- Maintain data quality rules and standards
- Create data dictionaries and lineage documentation

### 5. Automation
- Automate routine profiling tasks
- Build quality checks into ETL processes
- Implement real-time monitoring where possible

## Common Data Quality Issues and Solutions

| Issue | Detection Method | Solution |
|-------|-----------------|----------|
| Missing Values | NULL count analysis | Implement validation rules, default values |
| Duplicates | GROUP BY analysis | Create unique constraints, deduplication procedures |
| Invalid Formats | Pattern matching | Input validation, data standardization |
| Outliers | Statistical analysis | Business rule validation, manual review |
| Referential Integrity | JOIN analysis | Foreign key constraints, cascade rules |
| Business Logic Violations | Custom validation rules | Check constraints, triggers |

## Advanced Profiling Techniques

### 1. Pattern Analysis
```sql
-- Find common patterns in text fields
SELECT 
    LEFT(Phone, 3) AS AreaCode,
    COUNT(*) AS Frequency
FROM Customers 
WHERE Phone IS NOT NULL
GROUP BY LEFT(Phone, 3)
ORDER BY Frequency DESC;
```

### 2. Data Distribution Analysis
```sql
-- Analyze value distribution
SELECT 
    Gender,
    COUNT(*) AS Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM Customers
WHERE Gender IS NOT NULL
GROUP BY Gender;
```

### 3. Correlation Analysis
```sql
-- Check correlation between fields
SELECT 
    Country,
    AVG(CAST(TotalAmount AS FLOAT)) AS AvgOrderAmount
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY Country
ORDER BY AvgOrderAmount DESC;
```

## Integration with Data Quality Tools

### SQL Server Data Quality Services (DQS)
- Knowledge base management
- Data matching and deduplication
- Data cleansing projects

### SQL Server Integration Services (SSIS)
- Data profiling task
- Data quality transformations
- Error handling and logging

### Third-Party Tools
- Talend Data Quality
- Informatica Data Quality
- IBM InfoSphere QualityStage

## Conclusion

Data profiling is essential for maintaining high-quality data that supports reliable business decisions. By regularly profiling your data using SQL techniques like those demonstrated in this sample script, you can:

- Identify and fix data quality issues early
- Prevent downstream problems in reporting and analytics
- Ensure compliance with data governance standards
- Build trust in your data assets

The provided sample script serves as a comprehensive foundation that you can adapt to your specific data and business requirements.
