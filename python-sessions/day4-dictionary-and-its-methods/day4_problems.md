# Day 4 Practice Problems — Dictionary and its Methods

Difficulty: Medium to Hard. No solutions provided — work through the logic.

---

## Section A — Access and Safe Read

**P1. Safe Config Reader** *(Easy)*
```python
db_config = {
    "host": "localhost",
    "port": 5432,
    "db": "warehouse",
    "user": "admin"
}
```
1. Print each key-value pair using `.items()`
2. Access `"password"` safely — print `"NOT SET"` if missing
3. Access `"port"` with a default of `3306` — what does it return and why?
4. Check if `"user"` exists in the dict using `in`

---

**P2. Student Record Reader** *(Easy-Medium)*
```python
student = {
    "name": "Rahul",
    "course": "Data Engineering",
    "duration": "4 Months",
    "age": 23,
    "marks": [93, 85, 76, 90, 88],
    "details": [
        {"id": 1, "address": "Mumbai"},
        {"id": 2, "address": "Pune"}
    ]
}
```
1. Print name, course, and age
2. Print the first mark from `marks`
3. Print the average of all marks
4. Print the address from the second item in `details`
5. Print all keys of the first dict inside `details`

---

## Section B — Add, Update, Delete

**P3. Pipeline Config Builder** *(Medium)*
```python
pipeline = {
    "name": "etl_orders",
    "source": "postgres",
    "status": "pending"
}
```
1. Add key `"target"` with value `"s3"`
2. Add key `"batch_size"` with value `500`
3. Update `"status"` to `"running"`
4. Delete `"source"` key using `del`
5. Remove `"batch_size"` using `.pop()` and print the removed value
6. Print the final dict

---

**P4. Record Enrichment** *(Medium)*
```python
raw_record = {"order_id": "ORD-101", "amount": 1500.00, "status": "success"}
metadata   = {"source": "api", "ingested_at": "2024-01-15", "pipeline": "etl_orders"}
```
1. Merge `metadata` into `raw_record` using `.update()`
2. Print the enriched record
3. Add a new key `"is_valid"` = `True` if amount > 0 and status == "success", else `False`
4. Print the final enriched + validated record

---

## Section C — Iterating Dictionaries

**P5. Config Printer** *(Easy)*
```python
spark_config = {
    "spark.master": "local[*]",
    "spark.app.name": "ETL_Pipeline",
    "spark.executor.memory": "4g",
    "spark.driver.memory": "2g",
    "spark.sql.shuffle.partitions": "200"
}
```
1. Print all keys using `.keys()`
2. Print all values using `.values()`
3. Print each setting as `"key = value"` using `.items()`
4. Count how many settings have `"memory"` in the key name

---

**P6. Employee Department Grouping** *(Medium)*
```python
employees = [
    {"id": 1, "name": "Alice",  "dept": "Engineering", "salary": 95000},
    {"id": 2, "name": "Bob",    "dept": "Sales",        "salary": 72000},
    {"id": 3, "name": "Carol",  "dept": "Engineering",  "salary": 88000},
    {"id": 4, "name": "Dave",   "dept": "Data",         "salary": 102000},
    {"id": 5, "name": "Eve",    "dept": "Sales",        "salary": 78000},
    {"id": 6, "name": "Frank",  "dept": "Data",         "salary": 91000},
]
```
Using a dict to group:
1. Build a dict where key = department, value = list of employee names in that dept
2. Build a dict where key = department, value = average salary for that dept
3. Find the richest department (highest average salary)
4. Find total headcount per department

Expected for #1:
```python
{
  "Engineering": ["Alice", "Carol"],
  "Sales": ["Bob", "Eve"],
  "Data": ["Dave", "Frank"]
}
```

---

## Section D — Nested Dictionaries

**P7. API Response Parser** *(Medium)*
```python
api_response = {
    "status": "success",
    "pagination": {
        "page": 1,
        "page_size": 10,
        "total": 45,
        "total_pages": 5
    },
    "results": [
        {"id": 101, "name": "Alice",  "email": "alice@co.com",  "active": True},
        {"id": 102, "name": "Bob",    "email": "bob@co.com",    "active": False},
        {"id": 103, "name": "Carol",  "email": "carol@co.com",  "active": True},
    ]
}
```
1. Print `status`, current page, and total pages from the response
2. Print name and email of each result
3. Filter only active users from `results`
4. Print how many results are on this page vs total records

---

**P8. Nested Config Merger** *(Medium-Hard)*
```python
default_config = {
    "db": {"host": "localhost", "port": 5432, "timeout": 30},
    "api": {"base_url": "https://api.example.com", "retry": 3}
}
override_config = {
    "db": {"host": "prod-db.company.com", "port": 5432},
    "api": {"retry": 5, "timeout": 10}
}
```
Merge `override_config` into `default_config` at the nested level (not top-level `.update()` which would wipe the whole `"db"` key):
1. The final `db.host` should be `"prod-db.company.com"`
2. The final `db.timeout` should still be `30` (not overwritten since override has no timeout for db)
3. The final `api.retry` should be `5`
4. The final `api.timeout` should be `10`
5. Print the merged config

---

## Section E — Mixed / Hard

**P9. Frequency Counter** *(Medium)*
```python
pipeline_logs = [
    "INFO", "ERROR", "INFO", "WARN", "ERROR",
    "INFO", "INFO", "ERROR", "WARN", "INFO"
]
```
Using a dict (no `Counter` from collections):
1. Count occurrences of each log level
2. Print the most common log level
3. Print levels that appeared more than 2 times

Expected:
```python
{"INFO": 5, "ERROR": 3, "WARN": 2}
```

---

**P10. Invert a Dictionary** *(Medium)*
```python
status_codes = {
    200: "OK",
    201: "Created",
    400: "Bad Request",
    403: "Forbidden",
    404: "Not Found",
    500: "Internal Server Error"
}
```
1. Create an inverted dict where key = status message, value = status code
2. Look up the code for `"Not Found"` using the inverted dict
3. What happens if two codes have the same message? Handle it so no data is lost (value becomes a list)

---

**P11. Pipeline Run Summary** *(Hard)*
```python
pipeline_runs = [
    {"pipeline": "etl_orders",    "status": "SUCCESS", "rows": 1500, "duration_s": 45},
    {"pipeline": "etl_customers", "status": "FAILED",  "rows": 0,    "duration_s": 12},
    {"pipeline": "etl_orders",    "status": "SUCCESS", "rows": 1480, "duration_s": 43},
    {"pipeline": "etl_products",  "status": "SUCCESS", "rows": 320,  "duration_s": 18},
    {"pipeline": "etl_customers", "status": "SUCCESS", "rows": 900,  "duration_s": 30},
    {"pipeline": "etl_orders",    "status": "FAILED",  "rows": 0,    "duration_s": 5},
]
```
Build a summary dict per pipeline:
```python
{
  "etl_orders": {
      "total_runs": 3,
      "success": 2,
      "failed": 1,
      "total_rows": 2980,
      "avg_duration_s": 31.0
  },
  ...
}
```
Then:
1. Print the summary for each pipeline
2. Find the pipeline with the highest success rate
3. Find the pipeline that processed the most total rows

---

**P12. Schema Validator** *(Hard)*
```python
expected_schema = {
    "order_id":   str,
    "amount":     float,
    "status":     str,
    "customer_id": int
}

records = [
    {"order_id": "ORD-001", "amount": 250.00, "status": "success", "customer_id": 101},
    {"order_id": "ORD-002", "amount": "bad",  "status": "success", "customer_id": 102},
    {"order_id": "ORD-003", "amount": 180.00, "status": "pending", "customer_id": "abc"},
    {"order_id": "ORD-004", "amount": 320.00, "customer_id": 104},
]
```
For each record:
1. Check all expected keys are present — flag `"MISSING_FIELD"` if any are absent
2. Check each field's value is the correct type — flag `"TYPE_ERROR: <field>"` if wrong
3. Print a validation result per record:
```
ORD-001 → VALID
ORD-002 → INVALID: TYPE_ERROR: amount
ORD-003 → INVALID: TYPE_ERROR: customer_id
ORD-004 → INVALID: MISSING_FIELD: status
```

> This schema validation pattern is the foundation of data quality checks in every real ingestion pipeline.
