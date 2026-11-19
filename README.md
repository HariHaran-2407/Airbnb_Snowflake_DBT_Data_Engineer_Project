# Airbnb Data Engineering Pipeline: Snowflake, dbt & AWS S3

An ELT pipeline that loads Airbnb bookings, hosts and listings data from Amazon S3 into Snowflake and transforms it with dbt Core using a Bronze → Silver → Gold (Medallion) structure.

## Architecture

```
CSV files → Amazon S3 → Snowflake external stage → COPY INTO (STAGING)
          → dbt Bronze → dbt Silver → dbt Gold (fact, OBT)
                                  └→ dbt Snapshots (SCD Type 2)
```

## Tech Stack

- **Warehouse:** Snowflake (queries run in Snowsight)
- **Storage:** Amazon S3
- **Transformation:** dbt Core with the dbt-Snowflake adapter
- **Languages:** SQL, Jinja, Python 3.12
- **Version control:** Git

## What I Built

### 1. Loading data from S3 into Snowflake
- Created a CSV file format and an external stage pointing to an S3 bucket.
- Loaded `bookings.csv`, `hosts.csv` and `listings.csv` into staging tables with `COPY INTO`.
- Table definitions are in `DDL/ddl.sql`.

### 2. Medallion layers in dbt
| Layer | Models | Purpose |
|---|---|---|
| Bronze | `bronze_bookings`, `bronze_hosts`, `bronze_listings` | Raw data from staging, minimal changes |
| Silver | `silver_bookings`, `silver_hosts`, `silver_listings` | Cleaned and standardised data, price categorisation on listings |
| Gold | `obt`, `fact` | Analytics-ready tables |

### 3. Incremental models
Bronze and Silver models are incremental. On later runs they pick up only rows newer than the latest `CREATED_AT` already in the target table:

```sql
{{ config(materialized='incremental') }}
{% if is_incremental() %}
    WHERE CREATED_AT > (SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') FROM {{ this }})
{% endif %}
```

This captures new records. Rows that are updated after they were first loaded are not picked up by this logic.

### 4. Snapshots (SCD Type 2)
Snapshots for bookings, hosts and listings (`snapshots/dim_bookings.yml`, `dim_hosts.yml`, `dim_listings.yml`) keep the history of changed records with valid-from and valid-to dates.

### 5. Macros and Jinja
- `generate_schema_name`: custom schema naming so Bronze, Silver and Gold models land in `AIRBNB.BRONZE`, `AIRBNB.SILVER` and `AIRBNB.GOLD`.
- `tag`: categorises price per night into low / medium / high.
- `multiply` and `trimmer`: small reusable helpers for math and string cleanup.
- The One Big Table (`obt`) uses a Jinja loop over a config list to join bookings, listings and hosts.

### 6. Ephemeral models
`models/gold/ephemeral/` holds `bookings`, `hosts` and `listings` models used as intermediate steps for the Gold layer. They are inlined as CTEs and are not created as tables or views in Snowflake.

## Project Structure

```
AWS_DBT_Snowflake/
├── README.md
├── pyproject.toml
├── main.py
├── SourceData/                     # bookings.csv, hosts.csv, listings.csv
├── DDL/
│   ├── ddl.sql                     # staging table definitions
│   └── resources.sql
└── aws_dbt_snowflake_project/
    ├── dbt_project.yml
    ├── ExampleProfiles.yml
    ├── models/
    │   ├── sources/sources.yml
    │   ├── bronze/
    │   ├── silver/
    │   └── gold/                   # fact.sql, obt.sql, ephemeral/
    ├── macros/                     # generate_schema_name, tag, multiply, trimmer
    ├── snapshots/                  # dim_bookings, dim_hosts, dim_listings
    ├── analyses/                   # explore, if_else, loop
    └── tests/                      # source_tests.sql
```

## How to Run

### Prerequisites
- A Snowflake account
- An AWS account with an S3 bucket containing the three CSV files
- Python 3.12+

### Setup
```bash
git clone <your-repo-url>
cd AWS_DBT_Snowflake
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\Activate.ps1
pip install -e .
```

Dependencies (from `pyproject.toml`): `dbt-core`, `dbt-snowflake`, `sqlfmt`.

### Snowflake connection
Create `~/.dbt/profiles.yml` (see `ExampleProfiles.yml`):

```yaml
aws_dbt_snowflake_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your-account-identifier>
      user: <your-username>
      password: <your-password>
      role: <your-role>
      database: AIRBNB
      warehouse: COMPUTE_WH
      schema: dbt_schema
      threads: 4
```

### Load data from S3
1. Run `DDL/ddl.sql` to create the staging tables.
2. Create the file format and external stage, then load each file:

```sql
CREATE FILE FORMAT IF NOT EXISTS csv_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE OR REPLACE STAGE snowstage
  FILE_FORMAT = csv_format
  URL = 's3://<your-bucket>/source/';

COPY INTO HOSTS    FROM @snowstage FILES = ('hosts.csv')    CREDENTIALS = (aws_key_id = '<key>', aws_secret_key = '<secret>');
COPY INTO LISTINGS FROM @snowstage FILES = ('listings.csv') CREDENTIALS = (aws_key_id = '<key>', aws_secret_key = '<secret>');
COPY INTO BOOKINGS FROM @snowstage FILES = ('bookings.csv') CREDENTIALS = (aws_key_id = '<key>', aws_secret_key = '<secret>');
```

Never commit real AWS keys. The values above are placeholders.

### Run dbt
```bash
cd aws_dbt_snowflake_project
dbt debug                  # check the connection
dbt run                    # build all models
dbt run --select bronze.*  # one layer at a time (also silver.*, gold.*)
dbt snapshot               # build SCD Type 2 snapshots
```

To rebuild an incremental model from scratch: `dbt run --full-refresh`.

## Planned Improvements
- Add `schema.yml` tests (`unique`, `not_null`, `relationships`) and generate dbt docs with a lineage graph
- Use `updated_at` with a `unique_key` so incremental models also capture modified records
- Switch S3 access to a Snowflake storage integration instead of access keys
- Run dbt with a dedicated role instead of `ACCOUNTADMIN`

## Author
**Hariharan Thangarasu**
[LinkedIn](https://linkedin.com/in/hariharan-thangarasu) | [GitHub](https://github.com/hariharan-2407)
