# Day 3 - Practice Problems

**Topics covered:** Reading CSV, JSON, text files, inferSchema vs defined schema, nested data, explode, from_json, multiple files

All sample files are inside `data/`.

---

## Problem 1 — CSV basics

1. Read `employees.csv` with `header=True` and `inferSchema=True`. Show the data and schema.
2. Read the same file but use `.option()` chaining to also set `nullValue="N/A"` and `dateFormat="yyyy-MM-dd"`.
3. Read `employees_pipe.csv` — it uses `|` as separator. Show the result.

---

## Problem 2 — CSV with no header

1. Read `employees_no_header.csv` with `header=False`. What are the auto-generated column names?
2. Rename all columns to: `emp_id`, `name`, `department`, `salary`, `age`, `join_date`, `is_active` using `.toDF()`.
3. Read the same file again but this time provide a DDL schema string so Spark skips the auto-naming step entirely.

---

## Problem 3 — Dirty data and parse modes

Read `employees_dirty.csv` three ways:

1. **PERMISSIVE** (default) with `nullValue="N/A"` — which rows have NULLs and why?
2. **DROPMALFORMED** — how many rows remain compared to PERMISSIVE?
3. Describe (without running) what FAILFAST would do and when you would use it in production.

---

## Problem 4 — Defined schema (StructType)

Define a `StructType` schema for employees with these exact types:
- `emp_id`: IntegerType
- `name`: StringType
- `department`: StringType
- `salary`: DoubleType
- `age`: IntegerType
- `join_date`: DateType
- `is_active`: BooleanType

Read `employees.csv` using this schema. Compare the schema output with the inferred schema from Problem 1 — what changed?

---

## Problem 5 — JSON: flat JSONL

1. Read `employees_flat.json` with `inferSchema` (default). Show data and schema.
2. Note the column order — why are columns alphabetically sorted?
3. Read it again with `primitivesAsString=True`. What changed in the schema?
4. Read it with an explicit `StructType` schema that gives `salary` as `DoubleType` and `join_date` as `StringType`.

---

## Problem 6 — JSON: multi-line array

1. Read `employees_array.json` without any option. What error or unexpected result do you get?
2. Read it again with `multiLine=True`. Show data and schema.

---

## Problem 7 — Nested JSON: struct and array

Using `employees_nested.json`:

1. Read the file and call `printSchema()`. Identify which columns are `struct` and which are `array`.
2. Select `name`, `address.city`, `address.state` using dot notation.
3. Use `explode()` on the `skills` array — how many rows does the result have?
4. Use `explode_outer()` instead — what is the difference?

---

## Problem 8 — Deeply nested: orders

Using `orders.json`:

1. Read the file and show the schema. What is the type of the `items` column?
2. Explode the `items` array into individual rows.
3. After exploding, access `item.product`, `item.qty`, `item.price` as flat columns.
4. Convert the `items` column back to a JSON string using `to_json()`.

---

## Problem 9 — JSON string column (from_json, get_json_object, json_tuple)

Create this DataFrame manually:
```python
raw = [
    (101, '{"city": "Delhi",   "pincode": "110001", "state": "Delhi"}'),
    (102, '{"city": "Kolkata", "pincode": "700001", "state": "West Bengal"}'),
    (103, '{"city": "Jaipur",  "pincode": "302001", "state": "Rajasthan"}'),
]
df = spark.createDataFrame(raw, ["user_id", "address_json"])
```

1. Use `from_json()` with a `StructType` schema to parse `address_json` into a struct. Then select `user_id`, `city`, `pincode`, `state` as flat columns.
2. Use `get_json_object()` to extract only `city` from the JSON string.
3. Use `json_tuple()` to extract `city` and `state` in one call.

---

## Problem 10 — Text file / logs

Using `logs.txt`:

1. Read the file with `spark.read.text()`. What is the column name and type?
2. Use `regexp_extract()` to parse each line and create these columns:
   - `log_date` (e.g. `2024-01-15`)
   - `log_time` (e.g. `08:00:01`)
   - `log_level` (e.g. `INFO`, `ERROR`, `WARN`)
   - `event` (e.g. `UserLogin`, `DBConnection`)
3. Filter and show only `ERROR` level rows.
4. Count how many rows there are per log level. (hint: groupBy + count)

---

## Problem 11 — Multiple files

1. Read `employees.csv` and `employees_no_header.csv` together using a list of paths. How many total rows?
2. Add `input_file_name()` as a column called `source_file`. Show `name` and `source_file` for all rows.
3. (Linux/Mac/Databricks only) Read all CSV files in the `data/` folder using a folder path. How many rows and what schema does Spark infer?

---

## Bonus — Write modes

On Linux/Mac/Databricks (not Windows without winutils), write the employees DataFrame:
1. As CSV with header to `output/employees_csv/`
2. As JSON to `output/employees_json/`
3. Re-run the CSV write with `mode("overwrite")` vs `mode("error")` — what happens the second time for each?
