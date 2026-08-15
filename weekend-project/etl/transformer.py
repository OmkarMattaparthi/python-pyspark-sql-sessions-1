from datetime import datetime, timezone


def _parse_decimal(value):
    """Return float or None for decimal string fields."""
    try:
        return float(value) if value is not None else None
    except (ValueError, TypeError):
        return None


def _parse_timestamp(value):
    """Return ISO string as-is (psycopg2 handles it) or None."""
    if not value:
        return None
    return value  # already ISO 8601 — postgres TIMESTAMPTZ accepts it


def transform_payment(raw):
    """
    Cast and clean a single raw payment dict from the API.
    Returns a clean dict ready for DB insertion.
    """
    return {
        "id"           : raw.get("id"),
        "payment_id"   : raw.get("payment_id"),
        "session_id"   : raw.get("session_id"),
        "customer_id"  : raw.get("customer_id"),
        "gateway"      : raw.get("gateway"),
        "amount_aud"   : _parse_decimal(raw.get("amount_aud")),
        "gst"          : _parse_decimal(raw.get("gst")),
        "payment_mode" : raw.get("payment_mode"),
        "status"       : raw.get("status"),
        "processed_at" : _parse_timestamp(raw.get("processed_at")),
        "created_at"   : _parse_timestamp(raw.get("created_at")),
        "updated_at"   : _parse_timestamp(raw.get("updated_at")),
        "ingested_at"  : datetime.now(timezone.utc).isoformat(),
    }


def transform_payments(raw_records):
    """
    Transform a list of raw payment records.
    Skips records missing id or payment_id and logs them.
    Returns (clean_records, skip_count).
    """
    clean  = []
    skipped = 0

    for raw in raw_records:
        if not raw.get("id") or not raw.get("payment_id"):
            print(f"[transformer] Skipping record missing id/payment_id: {raw}")
            skipped += 1
            continue
        clean.append(transform_payment(raw))

    print(f"[transformer] {len(clean)} valid records, {skipped} skipped")
    return clean, skipped
