create database demo
create schema demo.demo_schema

drop schema demo.demo_scheam

create or replace warehouse my_wh warehouse_size = "large"

create or replace stage demo.demo_schema.weather_stage

DEMO.DEMO_SCHEMA.WEATHER_STAGEDEMO.DEMO_SCHEMA.WEATHER_STAGE



CREATE OR REPLACE STAGE DEMO.DEMO_SCHEMA.weather_stage
url='s3://snowflake-workshop-lab/weather-nyc'
FILE_FORMAT= (TYPE='json');

LIST @DEMO.DEMO_SCHEMA.weather_stage;


CREATE STORAGE INTEGRATION s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::593422056363:role/aws_snow_role'
ENABLED = TRUE
STORAGE_ALLOWED_LOCATIONS = ('s3://amzn-s3-snow-demo/' );


desc INTEGRATION s3_int

create or replace stage demo.demo_schema.aws_stage
Storage_integration=s3_int
url='s3://amzn-s3-snow-demo/'

LIST @DEMO.DEMO_SCHEMA.aws_stage;

-- we have to refer each column as this is csv not josn
select t.$1,t.$2,t.$3 from @DEMO.DEMO_SCHEMA.aws_stage t;

  