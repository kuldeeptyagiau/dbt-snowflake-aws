create or replace table demo.demo_schema.weather (data variant);

CREATE OR REPLACE FILE FORMAT DEMO.DEMO_SCHEMA.csv_format
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1;


COPY INTO DEMO.DEMO_SCHEMA.weather
FROM @DEMO.DEMO_SCHEMA.weather_stage


select  * from DEMO.DEMO_SCHEMA.weather


SELECT
data:city:findname,
data:city:coord:lat,
data:city:coord:lon,
data:clouds:all,
data:main:humidity,
data:main:pressure,
data:main:temp,
data:time,
data:weather[0]:main
FROM WEATHER;



- Command used to create the end table WEATHER_data:

CREATE OR REPLACE TABLE DEMO.DEMO_SCHEMA.WEATHER_data (
CITYNAME STRING,
LAT FLOAT,
LON FLOAT,
CLOUDS INTEGER,
HUMIDITY INTEGER,
PRESSURE FLOAT,
TEMP FLOAT,
TIME TIMESTAMP,
WEATHER STRING
);


- Examples on querying straight from a stage : https://docs.snowflake.com/en/user-guide/querying-stage#query-examples


- Command used to Copy data from the weather_stage into the end table WEATHER:
- for csv we hav eto refer all columns but in json all data is in one column

COPY INTO DEMO.DEMO_SCHEMA.WEATHER_data
FROM
(
select
t.$1:city:findname,
t.$1:city:coord:lat,
t.$1:city:coord:lon,
t.$1:clouds:all,
t.$1:main:humidity,
t.$1:main:pressure,
t.$1:main:temp,
t.$1:time,
t.$1:weather[0]:main
FROM @DEMO.DEMO_SCHEMA.weather_stage t);

select * from weather_data


-- LOAD DATA FROM AWS SAMPLE CODE --

/*--
In this Worksheet we will walk through templated SQL for the end to end process required
to load data from Amazon S3 into a table.

Snowflake Documentation on bulk loading from Amazon S3 - https://docs.snowflake.com/en/user-guide/data-load-s3
      --*/


-------------------------------------------------------------------------------------------
    -- Step 1: To start, let's set the Role and Warehouse context
        -- USE ROLE: https://docs.snowflake.com/en/sql-reference/sql/use-role
        -- USE WAREHOUSE: https://docs.snowflake.com/en/sql-reference/sql/use-warehouse
-------------------------------------------------------------------------------------------

--> To run a single query, place your cursor in the query editor and select the Run button (⌘-Return).
--> To run the entire worksheet, select 'Run All' from the dropdown next to the Run button (⌘-Shift-Return).

---> set Role Context
USE ROLE ACCOUNTADMIN;

---> set Warehouse Context
USE WAREHOUSE SNOWFLAKE_LEARNING_WH;

---> set the Database
USE DATABASE SNOWFLAKE_LEARNING_DB;

---> set the Schema
SET user_name = current_user();
SET schema_name = CONCAT($user_name, '_LOAD_DATA_FROM_AMAZON_AWS');
USE SCHEMA IDENTIFIER($schema_name);


-------------------------------------------------------------------------------------------
    -- Step 2: Create Table
        -- CREATE TABLE: https://docs.snowflake.com/en/sql-reference/sql/create-table
-------------------------------------------------------------------------------------------

---> create the Table
CREATE TABLE testtable
    (
    <col1_name> <COL1_TYPE>
    ,<col2_name> <COL2_TYPE>
    --> supported types: https://docs.snowflake.com/en/sql-reference/intro-summary-data-types.html
    )
    [COMMENT = '<string_literal>'];

---> query the empty Table
SELECT * FROM <table_name>;


-------------------------------------------------------------------------------------------
    -- Step 3: Create Storage Integrations
        -- CREATE STORAGE INTEGRATION: https://docs.snowflake.com/en/sql-reference/sql/create-storage-integration
-------------------------------------------------------------------------------------------

    /*--
      A Storage Integration is a Snowflake object that stores a generated identity and access management
      (IAM) entity for your external cloud storage, along with an optional set of allowed or blocked storage locations
      (Amazon S3, Google Cloud Storage, or Microsoft Azure).
    --*/

---> Create the Amazon S3 Storage Integration
    -- Configuring a Snowflake Storage Integration to Access Amazon S3: https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration

CREATE [ OR REPLACE ] STORAGE INTEGRATION [ IF NOT EXISTS ] <s3_integration_name>
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = '<iam_role>'
  [ STORAGE_AWS_OBJECT_ACL = 'bucket-owner-full-control' ]
  ENABLED = { TRUE | FALSE }
  STORAGE_ALLOWED_LOCATIONS = ('s3://<bucket>/<path>/' [ , 's3:://<bucket>/<path>/' ... ] )
  [ STORAGE_BLOCKED_LOCATIONS = ('s3:://<bucket>/<path>/' [ , 's3:://<bucket>/<path>/' ... ] ) ]
  [ COMMENT = '<string_literal>' ];

    /*--
      Execute the command below to retrieve the ARN and External ID for the AWS IAM user that was created automatically for your Snowflake account.
      You’ll use these values to configure permissions for Snowflake in your AWS Management Console:
          https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration#step-5-grant-the-iam-user-permissions-to-access-bucket-objects
    --*/

---> Describe our Integration
    -- DESCRIBE INTEGRATIONS: https://docs.snowflake.com/en/sql-reference/sql/desc-integration
DESCRIBE INTEGRATION <s3_integration_name>;

---> View our Storage Integrations
    -- SHOW INTEGRATIONS: https://docs.snowflake.com/en/sql-reference/sql/show-integrations

SHOW STORAGE INTEGRATIONS;


-------------------------------------------------------------------------------------------
    -- Step 6: Create Stage Objects
-------------------------------------------------------------------------------------------

    /*--
      A stage specifies where data files are stored (i.e. "staged") so that the data in the files
      can be loaded into a table.
    --*/

---> Create the Amazon S3 Stage
    -- Creating an S3 Stage: https://docs.snowflake.com/en/user-guide/data-load-s3-create-stage

CREATE [ OR REPLACE ] STAGE [ IF NOT EXISTS ] <s3_stage_name>
URL = { 's3://<bucket>[/<path>/]' | 's3://<bucket>[/<path>/]' }
STORAGE_INTEGRATION = <s3_integration_name> -- created in previous step
[ FILE_FORMAT = ( { FORMAT_NAME = '<file_format_name>' | TYPE = { CSV | JSON | AVRO | ORC | PARQUET | XML } [ formatTypeOptions ] } ) ]
[ COMMENT = '<string_literal>' ];

---> View our Stages
    -- SHOW STAGES: https://docs.snowflake.com/en/sql-reference/sql/show-stages

SHOW STAGES;


-------------------------------------------------------------------------------------------
    -- Step 7: Load Data from Stages
-------------------------------------------------------------------------------------------

---> Load data from the Amazon S3 Stage into the Table
    -- Copying Data from an S3 Stage: https://docs.snowflake.com/en/user-guide/data-load-s3-copy
    -- COPY INTO <table>: https://docs.snowflake.com/en/sql-reference/sql/copy-into-table

COPY INTO <table_name>
  FROM @<s3_stage_name>
    [ FILES = ( '<file_name>' [ , '<file_name>' ] [ , ... ] ) ]
    [ PATTERN = '<regex_pattern>' ]
    [ FILE_FORMAT = ( { FORMAT_NAME = '[<namespace>.]<file_format_name>' |
                        TYPE = { CSV | JSON | AVRO | ORC | PARQUET | XML } [ formatTypeOptions ] } ) ];

-------------------------------------------------------------------------------------------
    -- Step 8: Start querying your Data!
-------------------------------------------------------------------------------------------

---> Great job! You just successfully loaded data from your cloud provider into a Snowflake table
---> through an external stage. You can now start querying or analyzing the data.

SELECT * FROM <table_name>;
