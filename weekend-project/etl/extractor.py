import time
import requests
from config.settings import (
    PAYMENTS_ENDPOINT,
    PAGE_SIZE,
    REQUEST_DELAY_SEC,
    MAX_RETRIES,
    RETRY_BACKOFF_SEC,
)


def _get_page(token, page, page_size, updated_after=None):
    """Fetch a single page from the payments API with retry on 429."""
    headers = {"Authorization": f"Token {token}"}
    params  = {"page": page, "page_size": page_size}
    if updated_after:
        params["updated_after"] = updated_after   # ISO 8601 string

    for attempt in range(1, MAX_RETRIES + 1):
        response = requests.get(PAYMENTS_ENDPOINT, headers=headers, params=params, timeout=30)

        if response.status_code == 200:
            return response.json()

        if response.status_code == 429:
            wait = RETRY_BACKOFF_SEC * attempt
            print(f"[extractor] 429 Rate limit hit (page {page}, attempt {attempt}). Waiting {wait}s...")
            time.sleep(wait)
            continue

        response.raise_for_status()

    raise Exception(f"[extractor] Failed to fetch page {page} after {MAX_RETRIES} retries")


def fetch_all_payments(token, updated_after=None):
    """
    Fetch all payments pages and return a flat list of records.

    Args:
        token        : Bearer token from login
        updated_after: ISO timestamp string — only fetch records updated after this (incremental).
                       Pass None for full load.
    Returns:
        list of raw payment dicts
    """
    load_type = f"incremental (updated_after={updated_after})" if updated_after else "full"
    print(f"[extractor] Starting {load_type} load")

    all_records = []
    page = 1

    while True:
        print(f"[extractor] Fetching page {page} (page_size={PAGE_SIZE})...")
        body = _get_page(token, page, PAGE_SIZE, updated_after)

        records     = body.get("data", [])
        pagination  = body.get("pagination", {})
        total_pages = pagination.get("total_pages", 1)
        total       = pagination.get("total", "?")

        all_records.extend(records)
        print(f"[extractor] Page {page}/{total_pages} — {len(records)} records fetched (total so far: {len(all_records)}/{total})")

        if page >= total_pages:
            break

        page += 1
        time.sleep(REQUEST_DELAY_SEC)   # throttle between pages

    print(f"[extractor] Done. Total records fetched: {len(all_records)}")
    return all_records
