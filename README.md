Welcome to your new dbt project!

## Install python 
1. install python using uv "(curl -LsSf https://astral.sh/uv/install.sh | sh)
2. uv python install
3. uv venv
4. source .venv/Scripts/activate (windows)
   source .venv/bin/activate (linux)    

## check python verion
uv python list

## Install dependencies
uv pip install dbt-core
uv pip install dbt-snowflake

## check version
uv pip show dbt-core
uv pip show dbt-snowflake

## Initialize dbt 
dbt init
navigate to created folder during dbt init to check "dbt debug" command and it should display "All checks passed!"

## check dbt version
dbt --version   (Makre sure you have source your .venv to activate it)

## use same dependencies across team
1. create pyproject.toml file so that everyone 
2. lock dependencies by creating lock file "uv lock"
3. commit both .toml and .lock file in repo


### Using the starter project
Try running the following commands:
- dbt run
- dbt test
- dbt run -m stg_dbt_first
- dbt run -m stg_dbt_first --full-refresh
- dbt source freshness
- dbt source freshness --debug
- dbt test --debug


## install extension
1. Power User for dbt
2. make sure to select python interpreter from .venv file (use Ctrl+Shift+P to change interpreter)
3. make sure dbt core is tick marked in bottom left corner
- Snowflake Extension for Visual Studio Code (https://docs.snowflake.com/en/user-guide/vscode-ext)






### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
