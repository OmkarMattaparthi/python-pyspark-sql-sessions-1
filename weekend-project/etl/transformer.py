from datetime import datetime, timezone


def transform_payments(records):
    clean_records = []

    for record in records:
        clean = {
            "id"          : record["id"],
            "payment_id"  : record["payment_id"],
            "session_id"  : record["session_id"],
            "customer_id" : record["customer_id"],
            "gateway"     : record["gateway"],
            "amount_aud"  : float(record["amount_aud"]),
            "gst"         : float(record["gst"]),
            "payment_mode": record["payment_mode"],
            "status"      : record["status"],
            "processed_at": record["processed_at"],
            "created_at"  : record["created_at"],
            "updated_at"  : record["updated_at"],
            "ingested_at" : datetime.now(timezone.utc).isoformat(),
        }
        clean_records.append(clean)

    print(f"Transformed {len(clean_records)} records")
    return clean_records
