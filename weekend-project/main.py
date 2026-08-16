from api.auth import get_token
from database.connection import get_connection
from etl.extractor import fetch_payments
from etl.transformer import transform_payments
from etl.loader import create_tables, get_last_updated_at, insert_payments, save_pipeline_metadata

# choose load type: "full" or "incremental"
LOAD_TYPE = "incremental" # Full/Incremental

# Step 1: connect to DB
connection = get_connection()

# Step 2: create tables if not exist
create_tables(connection)

# Step 3: get auth token
token = get_token()

# Step 4: decide load type
last_updated_at = None
if LOAD_TYPE == "incremental":
    last_updated_at = get_last_updated_at(connection)
    print("Last updated at:", last_updated_at)

    if last_updated_at is None:
        print("No previous run found, switching to full load")
        LOAD_TYPE = "full"

# Step 5: fetch data from API
raw_records = fetch_payments(
    token,
    load_type=LOAD_TYPE,
    last_updated_at=last_updated_at,
    max_pages=5
)

# Step 6: transform
clean_records = transform_payments(raw_records)

# Step 7: insert into DB
insert_payments(connection, clean_records)

# Step 8: save metadata for next incremental run
if clean_records:
    max_updated_at = max(r["updated_at"] for r in clean_records)
else:
    max_updated_at = last_updated_at

save_pipeline_metadata(
    connection,
    LOAD_TYPE,
    len(clean_records),
    max_updated_at
)

connection.close()
print("Pipeline complete")
