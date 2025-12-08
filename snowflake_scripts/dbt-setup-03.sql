create database dbt_demo
create schema dbt_demo.dbt_schema
create or replace table dbt_first;

-- Create or replace the external stage pointing to the Bitcoin public S3 bucket
CREATE OR REPLACE STAGE dbt_demo.dbt_schema.dbt_STAGE
  URL = 's3://aws-public-blockchain/v1.0/btc/'
  FILE_FORMAT = (TYPE = PARQUET);

-- List files available in the stage
LIST @dbt_demo.dbt_schema.dbt_STAGE;


-- Create or replace a large warehouse for processing
-- CREATE OR REPLACE WAREHOUSE LARGE_WH
--   WAREHOUSE_SIZE = 'LARGE';

-- Query Bitcoin transaction data for a specific date - Please change to your own current date
SELECT
  t.$1:hash AS hashkey,
  t.$1:block_hash,
  t.$1:block_number,
  t.$1:block_timestamp,
  t.$1:fee,
  t.$1:input_value,
  t.$1:output_value AS output_btc,
  ROUND(t.$1:fee / t.$1:size, 12) AS fee_per_byte,
  t.$1:is_coinbase,
  t.$1:outputs
FROM @dbt_demo.dbt_schema.dbt_STAGE/transactions/date=2025-06-20 t;


-- Create the target table for Bitcoin transactions
CREATE OR REPLACE TABLE dbt_demo.dbt_schema.dbt_first (
  HASH_KEY VARCHAR,
  BLOCK_HASH VARCHAR,
  BLOCK_NUMBER INT,
  BLOCK_TIMESTAMP TIMESTAMP,
  FEE FLOAT,
  INPUT_VALUE FLOAT,
  OUTPUT_VALUE FLOAT,
  FEE_PER_BYTE FLOAT,
  IS_COINBASE BOOLEAN,
  OUTPUTS VARIANT
);


-- Copy data from stage into the BTC table, with pattern filter for file names
COPY INTO dbt_demo.dbt_schema.dbt_first
FROM (
  SELECT
    t.$1:hash AS hashkey,
    t.$1:block_hash,
    t.$1:block_number,
    t.$1:block_timestamp,
    t.$1:fee,
    t.$1:input_value,
    t.$1:output_value AS output_btc,
    ROUND(t.$1:fee / t.$1:size, 12) AS fee_per_byte,
    t.$1:is_coinbase,
    t.$1:outputs
  FROM @dbt_demo.dbt_schema.dbt_STAGE/transactions t
)
PATTERN = '.*/[0-9]{6,7}[.]snappy[.]parquet';


select * from dbt_first limit 10


CREATE OR REPLACE TASK dbt_demo.dbt_schema.dbt_first_LOAD_TASK
  WAREHOUSE = MY_WH
  SCHEDULE = '2 HOUR'
AS
COPY INTO dbt_demo.dbt_schema.dbt_first
FROM (
  SELECT
    t.$1:hash AS hashkey,
    t.$1:block_hash,
    t.$1:block_number,
    t.$1:block_timestamp,
    t.$1:fee,
    t.$1:input_value,
    t.$1:output_value AS output_btc,
    ROUND(t.$1:fee / t.$1:size, 12) AS fee_per_byte,
    t.$1:is_coinbase,
    t.$1:outputs
  FROM @dbt_demo.dbt_schema.dbt_STAGE/transactions t
)
PATTERN = '.*/[0-9]{6,7}[.]snappy[.]parquet';

ALTER TASK dbt_demo.dbt_schema.dbt_first_LOAD_TASK resume
ALTER TASK dbt_demo.dbt_schema.dbt_first_LOAD_TASK suspend


execute task dbt_demo.dbt_schema.dbt_first_LOAD_TASK

select max(BLOCK_TIMESTAMP), count(*) from dbt_first
-- 2025-12-07 00:20:39.000 , 6120

select max(BLOCK_TIMESTAMP), count(*) from stg_dbt_first
-- 2025-12-07 00:20:39.000 , 6120


select * from stg_dbt_first_output