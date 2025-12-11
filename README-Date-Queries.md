# Date Queries for Data Engineering Interviews

This repository contains a comprehensive collection of SQL date queries, variations, and edge cases designed for data engineering interview preparation and learning.

## 📁 File Structure

### 1. `mssql/date-queries-interview-prep.sql`
**SQL Server/T-SQL Date Queries**
- Basic date operations (GETDATE, DATEADD, DATEDIFF)
- Date formatting and conversion
- Date parts extraction (YEAR, MONTH, DAY, etc.)
- Leap year handling and edge cases
- Business date calculations
- Date validation with error handling
- Advanced scenarios (overlapping ranges, age calculations)
- Performance optimization tips
- Common interview questions with solutions

### 2. `snowflake/date-queries-snowflake-interview.sql`
**Snowflake-Specific Date Queries**
- Current timestamp functions (CURRENT_TIMESTAMP, GETDATE, SYSDATE)
- Timezone conversions with CONVERT_TIMEZONE
- Date formatting with TO_VARCHAR
- Business date functions (LAST_DAY, DATE_TRUNC, NEXT_DAY)
- Date series generation with TABLE(GENERATOR)
- Advanced date parsing scenarios
- Customer retention cohort analysis
- Time series gap detection
- Performance optimization for Snowflake

### 3. `data-engineering-edge-cases-interview.sql`
**Complex Real-World Scenarios**
- Timezone and daylight saving transitions
- Late-arriving and out-of-order data processing
- Data quality and deduplication strategies
- Window function edge cases with NULLs
- Hierarchical data with recursive CTEs
- Slowly Changing Dimensions (SCD Type 2)
- Event streaming and session analysis
- Data pipeline monitoring and anomaly detection

### 4. `sample-datasets-and-performance.sql`
**Test Data and Performance Tuning**
- Sample datasets (customers, orders, events, metrics)
- Performance optimization examples
- SARGable vs non-SARGable predicates
- Efficient window function usage
- Date dimension table creation
- Indexing strategies
- Query monitoring and debugging

## 🚀 Quick Start

### For SQL Server/T-SQL:
1. Open `mssql/date-queries-interview-prep.sql`
2. Execute individual query blocks to practice
3. Modify dates and parameters to test different scenarios

### For Snowflake:
1. Open `snowflake/date-queries-snowflake-interview.sql`
2. Run queries in Snowflake console or your preferred client
3. Create sample datasets using `sample-datasets-and-performance.sql`

## 🎯 Interview Topics Covered

### Core Date Operations
- Current date/time functions
- Date arithmetic (adding/subtracting intervals)
- Date formatting and parsing
- Date part extraction
- Date range filtering

### Edge Cases & Challenges
- Leap year calculations
- Timezone handling and DST transitions
- NULL date handling
- Date validation
- Business day calculations
- Holiday detection

### Advanced Scenarios
- Customer retention analysis
- Session identification
- Data quality monitoring
- Time series analysis
- Hierarchical date relationships
- Performance optimization

### Data Engineering Specific
- Late-arriving data handling
- Out-of-order event processing
- Slowly changing dimensions
- Data pipeline monitoring
- Anomaly detection in time series
- Cross-timezone data processing

## 🔧 Usage Tips

### Running Queries
1. **Copy individual sections**: Don't run entire files at once
2. **Use WITH clauses**: Most examples use CTEs for self-contained examples
3. **Modify test data**: Adjust dates and values to test edge cases
4. **Check syntax**: Some functions may vary between SQL dialects

### Common Query Patterns
```sql
-- Date range filtering (SARGable)
WHERE date_column >= '2023-01-01' 
  AND date_column < '2024-01-01'

-- Window functions with date partitioning
OVER (PARTITION BY customer_id ORDER BY order_date)

-- Date dimension joins
FROM orders o
JOIN date_dimension d ON o.order_date = d.date_value
```

## 📝 Interview Question Examples

### Basic Level
- "Calculate the number of days between two dates"
- "Find all orders from the last 30 days"
- "Extract year, month, day from a timestamp"

### Intermediate Level
- "Calculate customer retention rate by month"
- "Find gaps in a time series"
- "Handle timezone conversions for global data"

### Advanced Level
- "Identify user sessions from event stream"
- "Implement slowly changing dimension logic"
- "Detect anomalies in pipeline metrics"

## ⚡ Performance Best Practices

### DO:
- Use SARGable predicates (`WHERE date_col >= '2023-01-01'`)
- Partition window functions appropriately
- Use date dimensions for complex calculations
- Create proper indexes on date columns

### DON'T:
- Apply functions to date columns in WHERE clause
- Use unbounded window functions on large datasets
- Convert dates unnecessarily
- Ignore timezone implications

## 🛠 Troubleshooting

### Common Issues:
1. **Syntax errors**: Check SQL dialect compatibility
2. **Date format issues**: Ensure proper date literal format
3. **Timezone problems**: Use explicit timezone conversions
4. **Performance issues**: Check for non-SARGable predicates

### Testing Approach:
1. Start with simple date operations
2. Add complexity gradually
3. Test edge cases (leap years, DST, NULLs)
4. Validate business logic
5. Check performance with larger datasets

## 📚 Additional Resources

- Database-specific date function documentation
- Timezone database information
- SQL performance tuning guides
- Data quality best practices

---

**Note**: These queries are designed for learning and interview preparation. Always test thoroughly before using in production environments.
