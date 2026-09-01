# Day 2 - Reading Files in PySpark

---

## Table of Contents
1. [How Spark Reads Files](#1-how-spark-reads-files)
2. [Reading CSV](#2-reading-csv)
3. [Schema - inferSchema vs Defined Schema](#3-schema---inferschema-vs-defined-schema)
4. [Reading JSON](#4-reading-json)
5. [Handling Nested JSON](#5-handling-nested-json)
6. [Reading Plain Text Files](#6-reading-plain-text-files)
7. [Reading Multiple Files](#7-reading-multiple-files)
8. [Write Modes](#8-write-modes)
9. [Key Options Reference](#9-key-options-reference)

---

## 1. How Spark Reads Files

Spark reads files **lazily** - calling `spark.read.csv(...)` does NOT read the data yet.
The read only happens when an action is triggered (`show()`, `count()`, `write()`).

### The read API pattern

```
spark.read
     .format("csv")          # or json, parquet, text, orc
     .option("key", "value") # one or more options
     .schema(my_schema)      # optional - define schema explicitly
     .load("path/to/file")   # trigger the plan creation
```

Shorthand equivalents:
```python
spark.read.csv("path")     # same as .format("csv").load("path")
spark.read.json("path")    # same as .format("json").load("path")
spark.read.parquet("path") # same as .format("parquet").load("path")
spark.read.text("path")    # same as .format("text").load("path")
```

---

## 2. Reading CSV

### Most common options

| Option | Values | Default | What it does |
|---|---|---|---|
| `header` | `true` / `false` | `false` | First row is column names |
| `inferSchema` | `true` / `false` | `false` | Auto-detect column types |
| `sep` | any string | `,` | Column delimiter |
| `nullValue` | any string | `""` | String to treat as NULL |
| `nanValue` | any string | `NaN` | String to treat as NaN |
| `dateFormat` | pattern string | `yyyy-MM-dd` | Parse date columns |
| `timestampFormat` | pattern string | ISO 8601 | Parse timestamp columns |
| `multiLine` | `true` / `false` | `false` | Allow values spanning multiple lines |
| `mode` | `PERMISSIVE` / `DROPMALFORMED` / `FAILFAST` | `PERMISSIVE` | How to handle bad rows |
| `encoding` | `UTF-8`, `UTF-16`, etc. | `UTF-8` | File character encoding |
| `quote` | any char | `"` | Quote character for wrapping values |
| `escape` | any char | `\` | Escape character inside quotes |
| `ignoreLeadingWhiteSpace` | `true` / `false` | `false` | Strip leading spaces |
| `ignoreTrailingWhiteSpace` | `true` / `false` | `false` | Strip trailing spaces |
| `columnNameOfCorruptRecord` | column name | `_corrupt_record` | Column to store bad rows in PERMISSIVE mode |

### Parse modes explained

- **PERMISSIVE** (default): Reads all rows. Corrupt rows get NULL for all columns. The raw bad row is stored in `_corrupt_record` column if schema is defined.
- **DROPMALFORMED**: Silently drops rows that can't be parsed.
- **FAILFAST**: Throws an exception on the first bad row. Use in production to catch data quality issues early.

---

## 3. Schema - inferSchema vs Defined Schema

### inferSchema (automatic, convenient)

```python
df = spark.read.csv("file.csv", header=True, inferSchema=True)
```

- Spark reads the file **twice**: first pass to sample and detect types, second pass to load data
- Slower on large files
- May guess wrong (e.g. a zip code `"07001"` becomes integer `7001`)
- Fine for exploration and small files

### Defined Schema (explicit, production-ready)

```python
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DoubleType, BooleanType, DateType

schema = StructType([
    StructField("emp_id",     IntegerType(), True),
    StructField("name",       StringType(),  True),
    StructField("department", StringType(),  True),
    StructField("salary",     DoubleType(),  True),
    StructField("age",        IntegerType(), True),
    StructField("join_date",  DateType(),    True),
    StructField("is_active",  BooleanType(), True),
])

df = spark.read.schema(schema).csv("file.csv", header=True)
```

- File is read **once** - faster
- You control exact types
- Mismatched values become NULL (in PERMISSIVE mode)
- Recommended for production pipelines

### Common PySpark data types

| Type | Python class | Use for |
|---|---|---|
| String | `StringType()` | Text |
| Integer | `IntegerType()` | Whole numbers (32-bit) |
| Long | `LongType()` | Large whole numbers (64-bit) |
| Double | `DoubleType()` | Decimal numbers (64-bit float) |
| Float | `FloatType()` | Decimal numbers (32-bit float) |
| Boolean | `BooleanType()` | true/false |
| Date | `DateType()` | Date only (yyyy-MM-dd) |
| Timestamp | `TimestampType()` | Date + time |
| Decimal | `DecimalType(p,s)` | Fixed precision numbers (finance) |

### DDL schema string (shortcut)

Instead of StructType, you can write schema as a SQL DDL string:

```python
schema = "emp_id INT, name STRING, department STRING, salary DOUBLE, age INT"
df = spark.read.schema(schema).csv("file.csv", header=True)
```

---

## 4. Reading JSON

### Two JSON formats Spark supports

**1. JSON Lines (JSONL) - one JSON object per line (default)**
```
{"id": 1, "name": "Alice"}
{"id": 2, "name": "Bob"}
```
Spark reads this natively - each line = one row.

**2. Multi-line JSON - entire file is one JSON array**
```json
[
  {"id": 1, "name": "Alice"},
  {"id": 2, "name": "Bob"}
]
```
Requires `multiLine=True` option.

### Key JSON options

| Option | Values | Default | What it does |
|---|---|---|---|
| `multiLine` | `true` / `false` | `false` | Read whole file as one JSON doc |
| `allowComments` | `true` / `false` | `false` | Allow `//` and `/* */` comments |
| `allowUnquotedFieldNames` | `true` / `false` | `false` | Allow `{name: "Alice"}` style |
| `allowSingleQuotes` | `true` / `false` | `false` | Allow `{'name': 'Alice'}` |
| `allowNumericLeadingZeros` | `true` / `false` | `false` | Allow `007` as a number |
| `mode` | `PERMISSIVE` / `DROPMALFORMED` / `FAILFAST` | `PERMISSIVE` | Bad record handling |
| `dateFormat` | pattern | `yyyy-MM-dd` | Date parsing |
| `timestampFormat` | pattern | ISO 8601 | Timestamp parsing |
| `primitivesAsString` | `true` / `false` | `false` | Read all values as strings |
| `columnNameOfCorruptRecord` | column name | `_corrupt_record` | Store bad JSON rows |

---

## 5. Handling Nested JSON

JSON often contains nested objects and arrays. Spark reads these into special types.

### Nested object -> StructType
```json
{"name": "Alice", "address": {"city": "Bangalore", "pincode": "560001"}}
```
Access with dot notation: `col("address.city")`

### Array field -> ArrayType
```json
{"name": "Alice", "skills": ["Python", "Spark", "SQL"]}
```
Use `explode()` to flatten: each skill becomes its own row.

### Key functions for nested data

| Function | What it does |
|---|---|
| `col("struct.field")` | Access nested struct field |
| `explode(col("array_col"))` | One row per array element |
| `explode_outer(col("array_col"))` | Like explode but keeps rows with empty/null arrays |
| `posexplode(col("array_col"))` | Explode with position index |
| `from_json(col("json_string"), schema)` | Parse a JSON string column into struct |
| `to_json(col("struct_col"))` | Convert struct column to JSON string |
| `get_json_object(col("json_str"), "$.key")` | Extract one field from a JSON string |
| `json_tuple(col("json_str"), "k1", "k2")` | Extract multiple fields from a JSON string |

---

## 6. Reading Plain Text Files

```python
df = spark.read.text("file.txt")
```

Spark reads each line as a single string column called `value`.

Useful for:
- Log files
- Raw text that needs regex parsing
- Files with custom formats

After reading, use `regexp_extract()` or `split()` to parse the `value` column.

---

## 7. Reading Multiple Files

```python
# All CSVs in a folder
df = spark.read.csv("path/to/folder/", header=True)

# Wildcard pattern
df = spark.read.csv("data/emp_*.csv", header=True)

# List of specific files
df = spark.read.csv(["data/file1.csv", "data/file2.csv"], header=True)

# Add source filename as a column (useful when reading a folder)
df = spark.read.csv("data/", header=True).withColumn("source_file", input_file_name())
```

---

## 8. Write Modes

After reading and transforming, write results back with `.write`:

```python
df.write.mode("overwrite").csv("output/employees")
df.write.mode("overwrite").json("output/employees_json")
df.write.mode("overwrite").parquet("output/employees_parquet")
```

| Mode | Behaviour |
|---|---|
| `overwrite` | Delete existing data and write fresh |
| `append` | Add to existing data |
| `ignore` | Do nothing if path already exists |
| `error` (default) | Throw exception if path already exists |

---

## 9. Key Options Reference

### CSV vs JSON comparison

| Feature | CSV | JSON |
|---|---|---|
| Nested data | No | Yes |
| Schema in file | No (header = column names only) | Partial (inferred from values) |
| Human readable | Yes | Yes |
| Default in Spark | Needs `header=True` | Works out of box for JSONL |
| Multi-line values | `multiLine=True` | `multiLine=True` for arrays |
| Performance | Slower (text parsing) | Slower (text parsing) |
| Production format | Avoid - use Parquet | Avoid - use Parquet |

### Why Parquet in production?

Parquet is a **columnar binary format** - not covered today but worth knowing:
- 5-10x smaller than CSV (columnar compression)
- 10-100x faster reads (column pruning - only reads columns you need)
- Schema embedded in file - no inferSchema needed
- Supports complex types natively (arrays, structs)

Day 3 onwards we'll work with Parquet. For now CSV and JSON are used to understand reading fundamentals.
