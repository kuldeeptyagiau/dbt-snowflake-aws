## Summary of CTE Benefits
    More readable
    Modular (breaks big queries into steps)
    Reusable
    Avoid code duplication
    Supports recursion (unique advantage)
    Easier to debug than nested subqueries
## Regular Subquery (Independent Subquery) vs Correlated Subquery
Note:- In a SELECT statement, subquery may occur in the SELECT clause, FROM clause or the WHERE clause.
    A regular subquery executes only once and does not depend on the outer query.
    The subquery runs first.
    Its result is then used by the main query.
    The subquery does not reference columns from the outer query.
    Correlated Subquery
    A correlated subquery depends on the outer query and executes once per row of the outer query.
 ## split table
 Split a table into chunks by ROW_NUMBER() (equal-sized tables)
    Useful when you want, for example, 1 million rows in each table.
    Step 1: Assign row numbers
    WITH cte AS (
        SELECT *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
        FROM BigTable
    )
    Note: If you don’t care about the order using select null
    Step 2: Create multiple smaller tables
    SELECT * INTO SmallTable1 FROM cte WHERE rn BETWEEN 1 AND 1_000_000;   
## Group BY vs Partition By
🔵 When to use GROUP BY

When you need one row per group

When creating summary tables (fact aggregates, dim rollups)

Dashboard summary metrics

Example (daily revenue):

SELECT date, SUM(revenue)
FROM bookings
GROUP BY date;

🔵 When to use PARTITION BY

When you want aggregated values added to each row

Ranking, running totals, window calculations

Analytics without losing granularity

Example: Ranking drivers by daily trips:

SELECT
    driver_id,
    trip_id,
    ROW_NUMBER() OVER (PARTITION BY driver_id ORDER BY trip_timestamp) AS trip_rank
FROM fact_trips;

## Churned user
⭐ Interview-Ready One-Liner
“To find churned users, I calculate each user’s last activity date using MAX(activity_date). Any user whose last activity is older than 30 days is considered churned.”

SELECT driver_id
FROM (
    SELECT 
        driver_id,
        MAX(activity_ts) AS last_seen
    FROM driver_app_events
    GROUP BY driver_id
) d
WHERE last_seen < DATEADD(day, -30, GETDATE());

## Over
Using SUM as window function (with the OVER clause), does not reduce the no of records. Please note it’s not mandatory to use ORDER BY or PARTITION BY inside the OVER clause

## Where
We can also specify join conditions between two tables in the WHERE clause but Old Style Join (WHERE clause join condition) and are discoraged use JOIN ON clause

## Function 
When can a function NOT be called from SELECT query?
If the function includes DML operations like INSERT, UPDATE, DELETE etc then it cannot be called from a SELECT query. Because SELECT statement cannot change the state of the database.

