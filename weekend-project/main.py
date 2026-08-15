"""
VoltGrid Payments ETL Pipeline
================================
Usage:
    python main.py               # incremental load (default)
    python main.py --full        # full load (ignores last run cursor)
    python main.py --mode full
    python main.py --mode incremental
"""

import argparse
from datetime import datetime, timezone

from api.auth import get_token
from database.connection import get_connection
from etl.extractor import fetch_all_payments
from etl.transformer import transform_payments
from etl.loader import (
    ensure_schema,
    ensure_payments_table,
    ensure_metadata_table,
    get_last_updated_at,
    upsert_payments,
    get_max_updated_at,
    write_metadata,
)


def parse_args():
    parser = argparse.ArgumentParser(description="VoltGrid Payments ETL Pipeline")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--full", action="store_true", help="Force a full load")
    group.add_argument("--mode", choices=["full", "incremental"], default="incremental",
                       help="Load mode (default: incremental)")
    args = parser.parse_args()
    if args.full:
        args.mode = "full"
    return args


def main():
    args = parse_args()
    started_at = datetime.now(timezone.utc)

    print("=" * 60)
    print(f"  VoltGrid Payments Pipeline — mode={args.mode.upper()}")
    print(f"  Started at: {started_at.strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print("=" * 60)

    conn   = None
    status = "failed"
    records_fetched = records_inserted = records_skipped = 0
    last_updated_at = None

    try:
        # ── 1. DB setup ──────────────────────────────────────────────
        conn = get_connection()
        ensure_schema(conn)
        ensure_payments_table(conn)
        ensure_metadata_table(conn)

        # ── 2. Determine load cursor ─────────────────────────────────
        updated_after = None
        if args.mode == "incremental":
            updated_after = get_last_updated_at(conn)
            if updated_after:
                print(f"[main] Incremental load — fetching records updated after: {updated_after}")
            else:
                print("[main] No previous successful run found — falling back to full load")

        # ── 3. Authenticate ──────────────────────────────────────────
        token = get_token()

        # ── 4. Extract ───────────────────────────────────────────────
        raw_records = fetch_all_payments(token, updated_after=updated_after)
        records_fetched = len(raw_records)

        # ── 5. Transform ─────────────────────────────────────────────
        clean_records, records_skipped = transform_payments(raw_records)

        # ── 6. Load ──────────────────────────────────────────────────
        if clean_records:
            records_inserted = upsert_payments(conn, clean_records)
            last_updated_at  = get_max_updated_at(clean_records)
        else:
            print("[main] No valid records to load")

        status = "success"

    except Exception as e:
        print(f"\n[main] Pipeline FAILED: {e}")
        status = "failed"
        raise

    finally:
        # ── 7. Write metadata (always, even on failure) ──────────────
        if conn:
            try:
                write_metadata(
                    conn        = conn,
                    load_type   = args.mode,
                    status      = status,
                    records_fetched  = records_fetched,
                    records_inserted = records_inserted,
                    records_skipped  = records_skipped,
                    last_updated_at  = last_updated_at,
                    started_at       = started_at,
                )
            except Exception as meta_err:
                print(f"[main] Warning: could not write metadata — {meta_err}")
            conn.close()
            print("[main] DB connection closed")

        print("=" * 60)
        print(f"  Status   : {status.upper()}")
        print(f"  Fetched  : {records_fetched}")
        print(f"  Inserted : {records_inserted}")
        print(f"  Skipped  : {records_skipped}")
        print(f"  Cursor   : {last_updated_at}")
        print("=" * 60)


if __name__ == "__main__":
    main()
