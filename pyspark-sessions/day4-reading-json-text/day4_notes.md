# Day 4 - Reading JSON and Text Files in PySpark

> Data files are in `../day3-reading-files/data/` (shared with Day 3).

---

## Table of Contents
1. [JSON Formats Spark Supports](#1-json-formats-spark-supports)
2. [Reading Flat JSONL](#2-reading-flat-jsonl)
3. [Reading Multi-line JSON Array](#3-reading-multi-line-json-array)
4. [Nested JSON - Struct and Array Fields](#4-nested-json---struct-and-array-fields)
5. [explode and explode_outer](#5-explode-and-explode_outer)
6. [Array of Structs (Deeply Nested)](#6-array-of-structs-deeply-nested)
7. [Parsing JSON from a String Column](#7-parsing-json-from-a-string-column)
8. [Reading Plain Text Files](#8-reading-plain-text-files)
9. [JSON Options Reference](#9-json-options-reference)

---

## 1. JSON Formats Spark Supports

### JSONL — one object per line (default)

```
{"id": 1, "name": "Alice"}
{"id": 2, "name": "Bob"}
```

Spark reads this natively — each line = one row.

### Multi-line JSON array — whole file is one array

```json
[
  {"id": 1, "name": "Alice"},
  {"id": 2, "name": "Bob"}
]
```

Requires `multiLine=True`.

---

## 2. Reading Flat JSONL

```python
# inferSchema — columns sorted alphabetically
df = spark.read.json("employees_flat.json")
df.show()
df.printSchema()

# Explicit schema — control column order and types
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DoubleType

schema = StructType([
    StructField("emp_id",     IntegerType(), True),
    StructField("name",       StringType(),  True),
    StructField("salary",     DoubleType(),  True),
])
df = spark.read.schema(schema).json("employees_flat.json")

# Read all values as strings (delay casting)
df = spark.read.option("primitivesAsString", "true").json("employees_flat.json")
```

**Note:** JSON inferSchema reads the whole file once (not twice like CSV). Still, explicit schema is preferred for production.

---

## 3. Reading Multi-line JSON Array

```python
df = spark.read \
    .option("multiLine", "true") \
    .json("employees_array.json")
df.show()
```

Without `multiLine=True`, Spark reads line by line — the `[` and `]` brackets cause every row to fail to parse.

---

## 4. Nested JSON - Struct and Array Fields

Given this JSON:
```json
{"name": "Alice", "address": {"city": "Bangalore", "pincode": "560001"}, "skills": ["Python", "Spark"]}
```

Spark automatically maps:
- `address` → `StructType` (nested object)
- `skills` → `ArrayType` (array of strings)

```python
df = spark.read.json("employees_nested.json")
df.printSchema()
# root
#  |-- address: struct
#  |    |-- city: string
#  |    |-- pincode: string
#  |-- name: string
#  |-- skills: array
#  |    |-- element: string

# Access struct field with dot notation
from pyspark.sql.functions import col
df.select(col("name"), col("address.city"), col("address.state")).show()
```

---

## 5. explode and explode_outer

| Function | Behavior on NULL/empty array |
|---|---|
| `explode(col)` | Row is **dropped** |
| `explode_outer(col)` | Row is **kept**, array element = NULL |

```python
from pyspark.sql.functions import explode, explode_outer

# One row per skill — rows with no skills are dropped
df.select(col("name"), explode(col("skills")).alias("skill")).show()

# Same but keeps employees with no skills (skill = NULL)
df.select(col("name"), explode_outer(col("skills")).alias("skill")).show()
```

---

## 6. Array of Structs (Deeply Nested)

```json
{"order_id": "ORD001", "items": [{"product": "Laptop", "qty": 1, "price": 1200.0}]}
```

Pattern — explode the array, then access each struct's fields:

```python
from pyspark.sql.functions import col, explode, to_json

df = spark.read.json("orders.json")

# Step 1: explode items array -> each item becomes a struct column
df_exp = df.select("order_id", "customer", explode(col("items")).alias("item"))

# Step 2: access struct fields with dot notation
df_flat = df_exp.select(
    col("order_id"),
    col("customer"),
    col("item.product"),
    col("item.qty"),
    col("item.price")
)

# Convert struct/array column back to JSON string
df.select("order_id", to_json(col("items")).alias("items_json")).show(truncate=False)
```

---

## 7. Parsing JSON from a String Column

Real-world scenario: a VARCHAR column in a database stores JSON as text.

### Three tools

```python
from pyspark.sql.functions import from_json, get_json_object, json_tuple
from pyspark.sql.types import StructType, StructField, StringType

# Sample DataFrame with a JSON string column
raw = [(1, '{"city": "Bangalore", "pincode": "560001"}')]
df = spark.createDataFrame(raw, ["id", "addr_json"])
```

**from_json() — parse full string into a typed struct**
```python
addr_schema = StructType([
    StructField("city",    StringType(), True),
    StructField("pincode", StringType(), True),
])
df.withColumn("addr", from_json(col("addr_json"), addr_schema)) \
  .select("id", "addr.city", "addr.pincode").show()
```

**get_json_object() — extract one field using JSONPath**
```python
df.select(
    col("id"),
    get_json_object(col("addr_json"), "$.city").alias("city")
).show()
```

**json_tuple() — extract multiple fields at once**
```python
df.select(
    col("id"),
    json_tuple(col("addr_json"), "city", "pincode").alias("city", "pincode")
).show()
```

### When to use which

| Tool | Best for |
|---|---|
| `from_json` | Full parsing, nested access, type control |
| `get_json_object` | Extracting 1-2 fields quickly |
| `json_tuple` | Extracting several fields in one call |

---

## 8. Reading Plain Text Files

```python
df = spark.read.text("logs.txt")
# One column: "value" (StringType), one row per line
```

### Parsing with regexp_extract

```python
from pyspark.sql.functions import regexp_extract, col

# Log format: "2024-01-15 08:00:01 INFO  UserLogin ..."
df_logs = df.select(
    regexp_extract(col("value"), r"^(\d{4}-\d{2}-\d{2})", 1).alias("log_date"),
    regexp_extract(col("value"), r"^\S+ (\S+)", 1).alias("log_time"),
    regexp_extract(col("value"), r"^\S+ \S+ (\S+)", 1).alias("log_level"),
    regexp_extract(col("value"), r"^\S+ \S+ \S+\s+(\S+)", 1).alias("event"),
)

# Filter by level
df_logs.filter(col("log_level") == "ERROR").show()

# Count per level
df_logs.groupBy("log_level").count().show()
```

`regexp_extract(column, pattern, group)` — returns the matched group. Returns empty string `""` (not NULL) when no match.

---

## 9. JSON Options Reference

| Option | Default | What it does |
|---|---|---|
| `multiLine` | `false` | Read whole file as one JSON doc |
| `primitivesAsString` | `false` | Read numbers/booleans as strings |
| `allowComments` | `false` | Allow `//` and `/* */` in JSON |
| `allowSingleQuotes` | `false` | Allow `{'key': 'value'}` style |
| `mode` | `PERMISSIVE` | `PERMISSIVE` / `DROPMALFORMED` / `FAILFAST` |
| `dateFormat` | `yyyy-MM-dd` | Date parsing pattern |
| `timestampFormat` | ISO 8601 | Timestamp parsing pattern |
| `columnNameOfCorruptRecord` | `_corrupt_record` | Column to store bad JSON rows |
