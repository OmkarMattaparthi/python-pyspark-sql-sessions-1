import time
import requests
from config.settings import API_BASE_URL


def fetch_payments(token, load_type="full", last_updated_at=None, max_pages=None):
    url = f"{API_BASE_URL}/api/db/payments/"
    headers = {"Authorization": f"Token {token}"}

    all_records = []
    page = 1
    page_size = 100

    while True:
        params = {"page": page, "page_size": page_size}

        # incremental load — pass updated_after to filter only new records
        if load_type == "incremental" and last_updated_at:
            params["updated_after"] = last_updated_at

        response = requests.get(url, headers=headers, params=params)

        # rate limit hit — wait and retry
        if response.status_code == 429:
            print("Rate limit hit, waiting 10 seconds...")
            time.sleep(10)
            continue

        print(f"Page {page} status: {response.status_code}")
        data = response.json()

        records     = data["data"]
        total_pages = data["pagination"]["total_pages"]

        all_records.extend(records)
        print(f"Page {page}/{total_pages} — fetched {len(records)} records")

        if page >= total_pages:
            break

        if max_pages and page >= max_pages:
            print(f"Reached max_pages limit ({max_pages}), stopping early")
            break

        page += 1
        time.sleep(0.3)   # small pause between pages to avoid rate limit

    print(f"Total records fetched: {len(all_records)}")
    return all_records
