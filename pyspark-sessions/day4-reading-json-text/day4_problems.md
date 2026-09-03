# Day 4 - Practice Problems

**Topics:** Reading JSON (flat, multi-line, nested, array of structs), JSON string parsing, text/log files

All data files are in `../day3-reading-files/data/`.

---

## Problem 1 — Flat JSONL

1. Read `employees_flat.json` with no options (inferSchema). Show data and call `printSchema()`.
2. Notice the column order — why are they alphabetical?
3. Read it again with an explicit `StructType` schema. Make `salary` a `DoubleType` and `join_date` a `StringType`. Does the column order change?
4. Read it once more with `primitivesAsString=True`. What is the type of `emp_id` now?

---

## Problem 2 — Multi-line JSON array

1. Read `employees_array.json` without `multiLine=True`. What do you see?
2. Read it again with `multiLine=True`. How many rows and what schema?
3. Is the schema identical to reading `employees_flat.json`?

---

## Problem 3 — Nested struct

Using `employees_nested.json`:

1. Read the file and call `printSchema()`. Which columns are `struct` type and which are `array` type?
2. Select `name`, `address.city`, `address.state`, `address.pincode` using dot notation.
3. Filter employees whose `address.state` is `"Maharashtra"`.

---

## Problem 4 — explode

Using `employees_nested.json`:

1. Use `explode()` on the `skills` array. How many total rows result?
2. Show `name`, `department`, `skill` (the exploded column).
3. Now count how many skills each employee has: `groupBy("name").count()` on the exploded DataFrame.
4. What would `explode_outer()` produce differently? (Check with the same data or think it through.)

---

## Problem 5 — Array of structs (orders)

Using `orders.json`:

1. Read the file. What is the data type of the `items` column?
2. Explode the `items` array into a struct column named `item`.
3. Select `order_id`, `customer`, `item.product`, `item.qty`, `item.price` as flat columns.
4. Find the total revenue per order: multiply `qty * price`, then `groupBy("order_id").sum(...)`.
5. Convert the `items` column to a JSON string using `to_json()` and show the result.

---

## Problem 6 — from_json

Create this DataFrame:

```python
raw = [
    (101, '{"city": "Delhi",   "pincode": "110001", "state": "Delhi"}'),
    (102, '{"city": "Kolkata", "pincode": "700001", "state": "West Bengal"}'),
    (103, '{"city": "Jaipur",  "pincode": "302001", "state": "Rajasthan"}'),
]
df = spark.createDataFrame(raw, ["user_id", "address_json"])
```

1. Define a `StructType` schema for `city`, `pincode`, `state` — all `StringType`.
2. Use `from_json()` to parse `address_json` into a struct column called `address`.
3. Select `user_id`, `address.city`, `address.pincode`, `address.state` as flat columns.
4. Filter only rows where `address.state == "Delhi"`.

---

## Problem 7 — get_json_object and json_tuple

Using the same `df` from Problem 6:

1. Use `get_json_object()` to extract only `city`. What is the return type?
2. Use `json_tuple()` to extract `city` and `state` in one call.
3. Which approach would you use if you only need one field? Which if you need four fields?

---

## Problem 8 — Text file

Using `logs.txt`:

1. Read with `spark.read.text()`. What is the single column name and its type?
2. Use `regexp_extract()` to parse each line into: `log_date`, `log_time`, `log_level`, `event`.
3. Show only `ERROR` rows.
4. Show only `WARN` and `ERROR` rows using `isin()`.
5. Count how many log entries exist per `log_level`. Order by count descending.

---

## Problem 9 — Combining JSON + DataFrame ops

Using `orders.json`:

1. Read and flatten the orders (explode items).
2. Filter only `delivered` orders.
3. For each delivered order, calculate `line_total = qty * price`.
4. Find the top 3 most expensive individual line items (`orderBy line_total desc, show(3)`).

---

## Bonus — JSON with missing fields

Create a JSONL file (or use `spark.createDataFrame`) where some rows are missing fields:

```python
data = """{"id": 1, "name": "Alice", "city": "Delhi"}
{"id": 2, "name": "Bob"}
{"id": 3, "city": "Mumbai"}"""
```

Write this to a file or use `spark.read.json(spark.sparkContext.parallelize(data.splitlines()))`.

1. Read it with inferSchema. What value appears for missing fields?
2. What mode would you use to drop rows with missing required fields?
