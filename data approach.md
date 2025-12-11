## New data set approach

### Understand the Business Context and relevance
- where is it coming from
- how is the data sourced (Ingested)
- how is the data collected
- how often is the data updated
- What problem are we solving?
- Who are the users (analysts, ML team, operations)?
- What KPIs or insights do they need?
- what are the potential biases in data if there are what are the risk and implication

### RAW DataSET PROFILING OR INSPECTION
- null/missing value  
- duplicate 
- data structure/ schema and types and ranges
- correct data format
- Standardize and normalize data
- Outliers
- Incomplete or missing
- data distribution and summary statistics (mean , median and mode)

### Identify the Grain and Primary Keys
Every dataset must have a clear grain.

Examples:
- One record per trip
- One record per customer per day
- One record per booking event

Check if dataset has a reliable PK:
```sql
SELECT id, COUNT(*) 
FROM table
GROUP BY id
HAVING COUNT(*) > 1;
```
📌 Example answer:
"I determine the grain—e.g., each row represents one booking. Then I check uniqueness of booking_id to validate it as a primary key."
This shows you understand modeling.

### Check Relationships With Other Datasets
If more tables exist, identify joins:
- customer_id
- driver_id
- vehicle_id
📌 Example answer:
"I check how this dataset joins with others, such as customer_dim or driver_dim, and validate referential integrity."

### Define Transformations (Cleaning + Standardization)
This is where you discuss:
✔ Missing value handling
✔ Standardize date formats
✔ Convert data types
✔ Deal with duplicates
✔ Remove invalid rows (e.g., negative trip distance)
✔ Normalize category values
📌 Example answer:
"I apply data quality checks—remove negative trip distance, convert timestamps to UTC, dedupe on booking_id, and standardize categorical fields."

### Model It into a Lakehouse (Bronze → Silver → Gold)
✔ Bronze (raw)
JSON, CSV, IoT events, CDC, Kafka messages stored in Delta.
✔ Silver (clean + conformed)
- Normalize schema
- Join to dimensions
- Apply business rules
✔ Gold (curated for analytics)
- Fact tables
- Dimension tables
- Aggregations
- SCD Type 2 handling for dimensions
📌 Example answer:
"I land the data as-is in Bronze, clean it and standardize in Silver, then create analytical facts and dims in Gold."

### Outputs & Insights (Final Deliverable)
Once clean, you highlight:
- Top KPIs
- Metrics
- Trends
- Anomalies
- Time-series breakdown
- Customer segments
