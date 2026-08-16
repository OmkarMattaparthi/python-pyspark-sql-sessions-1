from api.auth import get_token
from database.connection import get_connection
from etl.extractor import (
    fetch_payments,
    fetch_sessions,
    fetch_customers,
    fetch_vehicles,
    fetch_stations,
    fetch_partners,
    fetch_energy_prices,
)
from etl.transformer import (
    transform_payments,
    transform_sessions,
    transform_customers,
    transform_vehicles,
    transform_stations,
    transform_partners,
    transform_energy_prices,
)
from etl.loader import (
    create_tables,
    get_last_updated_at,
    insert_payments,
    insert_sessions,
    insert_customers,
    insert_vehicles,
    insert_stations,
    insert_partners,
    insert_energy_prices,
    save_pipeline_metadata,
)

# ── Config ────────────────────────────────────────────────────────────────────
# set to "full" or "incremental"
LOAD_TYPE = "incremental"

# limit pages per API for testing — set to None for full load
MAX_PAGES = 5

# list of all pipelines to run: (pipeline_name, fetch_fn, transform_fn, insert_fn)
PIPELINES = [
    ("payments",      fetch_payments,      transform_payments,      insert_payments),
    ("sessions",      fetch_sessions,      transform_sessions,      insert_sessions),
    ("customers",     fetch_customers,     transform_customers,     insert_customers),
    ("vehicles",      fetch_vehicles,      transform_vehicles,      insert_vehicles),
    ("stations",      fetch_stations,      transform_stations,      insert_stations),
    ("partners",      fetch_partners,      transform_partners,      insert_partners),
    ("energy_prices", fetch_energy_prices, transform_energy_prices, insert_energy_prices),
]

# ── Setup ─────────────────────────────────────────────────────────────────────

# Step 1: connect to DB
connection = get_connection()

# Step 2: create all bronze tables if not exist
create_tables(connection)

# Step 3: get auth token
token = get_token()

# ── Run each pipeline ─────────────────────────────────────────────────────────

for pipeline_name, fetch_fn, transform_fn, insert_fn in PIPELINES:
    print(f"\n{'='*50}")
    print(f"Pipeline: {pipeline_name.upper()}")
    print(f"{'='*50}")

    # Step 4: decide load type
    load_type = LOAD_TYPE
    last_updated_at = None

    if load_type == "incremental":
        last_updated_at = get_last_updated_at(connection, pipeline_name)
        print(f"Last updated at: {last_updated_at}")

        if last_updated_at is None:
            print("No previous run found, switching to full load")
            load_type = "full"

    # Step 5: fetch
    raw_records = fetch_fn(token, load_type=load_type, last_updated_at=last_updated_at, max_pages=MAX_PAGES)

    # Step 6: transform
    clean_records = transform_fn(raw_records)

    # Step 7: insert
    insert_fn(connection, clean_records)

    # Step 8: save metadata
    if clean_records:
        max_updated_at = max(r["updated_at"] for r in clean_records if r.get("updated_at"))
    else:
        max_updated_at = last_updated_at

    save_pipeline_metadata(connection, pipeline_name, load_type, len(clean_records), max_updated_at)

# ── Done ──────────────────────────────────────────────────────────────────────

connection.close()
print(f"\n{'='*50}")
print("All pipelines complete")
print(f"{'='*50}")
