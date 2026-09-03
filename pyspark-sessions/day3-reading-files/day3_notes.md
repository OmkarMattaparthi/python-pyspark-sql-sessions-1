# Day 3 - Reading CSV Files in PySpark

> **Also in this folder:** [jupyter_setup.md](jupyter_setup.md) — Jupyter Notebook installation guide for Windows / macOS / Ubuntu, running PySpark in notebooks, keyboard shortcuts, and troubleshooting.

---

## Table of Contents
1. [How Spark Reads Files](#1-how-spark-reads-files)
2. [Reading CSV - Basic](#2-reading-csv---basic)
3. [option() and options() Styles](#3-option-and-options-styles)
4. [No Header Row](#4-no-header-row)
5. [Custom Delimiter](#5-custom-delimiter)
6. [Multiline Values](#6-multiline-values)
7. [Dirty Data and Parse Modes](#7-dirty-data-and-parse-modes)
8. [inferSchema vs Defined Schema](#8-inferschema-vs-defined-schema)
9. [Reading Multiple CSV Files](#9-reading-multiple-csv-files)
10. [Write Modes](#10-write-modes)
11. [CSV Options Reference](#11-csv-options-reference)

---

## 1. How Spark Reads Files

Spark reads files **lazily** — calling `spark.read.csv(...)` does NOT read the data yet. The read only happens when an action is triggered (`show()`, `count()`, `write()`).

### The read API — two styles

**Shorthand (most common):**
```python
spark.read.csv("path/to/file.csv", header=True, inferSchema=True)
```

**Full format style (explicit):**
```python
spark.read \
    .format("csv") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .load("path/to/file.csv")
```

Both are identical. The shorthand is preferred for CSV.

---

## 2. Reading CSV - Basic

```python
df = spark.read.csv("employees.csv", header=True, inferSchema=True)
df.show()
df.printSchema()
```

| Parameter | Default | What it does |
|---|---|---|
| `header` | `False` | First row becomes column names |
| `inferSchema` | `False` | Auto-detect column types (reads file twice) |

Without `header=True`, Spark names columns `_c0`, `_c1`, `_c2` ...  
Without `inferSchema=True`, every column is read as `StringType`.

---

## 3. option() and options() Styles

Two ways to pass multiple options:

```python
# Chain .option() one at a time — clearest to read
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("nullValue", "N/A") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv("file.csv")

# Pass all at once with .options()
df = spark.read \
    .options(header="true", inferSchema="true", nullValue="N/A") \
    .csv("file.csv")
```

---

## 4. No Header Row

When the file has no header, Spark uses `_c0`, `_c1`, `_c2` ...

```python
df = spark.read.csv("file.csv", header=False, inferSchema=True)
df.show()  # columns: _c0, _c1, _c2 ...

# Rename all columns at once
df = df.toDF("emp_id", "name", "department", "salary", "age", "join_date", "is_active")
```

Or provide a schema (see Section 8) — Spark uses the schema's field names directly.

---

## 5. Custom Delimiter

```python
# Pipe-delimited
df = spark.read.csv("file.csv", header=True, sep="|")

# Tab-delimited (TSV)
df = spark.read.csv("file.tsv", header=True, sep="\t")

# Semicolon
df = spark.read.csv("file.csv", header=True, sep=";")
```

Default separator is `,`.

---

## 6. Multiline Values

When a column value contains a newline and is wrapped in quotes:

```
emp_id,name,bio
1,Alice,"Engineer,
loves Python"
```

```python
df = spark.read.csv(
    "file.csv",
    header=True,
    multiLine=True,
    quote='"',
    escape='"'
)
```

Without `multiLine=True`, Spark treats the newline inside the quotes as a new row and the record breaks.

---

## 7. Dirty Data and Parse Modes

| Mode | Behavior |
|---|---|
| `PERMISSIVE` (default) | Keeps all rows. Values that don't match the schema become NULL. |
| `DROPMALFORMED` | Silently drops rows that cannot be parsed. |
| `FAILFAST` | Throws an exception on the first bad row. Use in production. |

```python
# PERMISSIVE (default) + treat "N/A" as NULL
df = spark.read.csv("dirty.csv", header=True, inferSchema=True, nullValue="N/A")

# DROPMALFORMED
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("mode", "DROPMALFORMED") \
    .csv("dirty.csv")

# FAILFAST
df = spark.read \
    .option("header", "true") \
    .option("mode", "FAILFAST") \
    .csv("dirty.csv")
```

---

## 8. inferSchema vs Defined Schema

### inferSchema (automatic, convenient)

```python
df = spark.read.csv("file.csv", header=True, inferSchema=True)
```

- Reads the file **twice** — slow on large files
- May guess wrong (zip code `"07001"` → integer `7001`)
- Fine for exploration and small files

### StructType — explicit schema (production-ready)

```python
from pyspark.sql.types import (
    StructType, StructField,
    IntegerType, StringType, DoubleType, BooleanType, DateType
)

schema = StructType([
    StructField("emp_id",     IntegerType(), True),
    StructField("name",       StringType(),  True),
    StructField("department", StringType(),  True),
    StructField("salary",     DoubleType(),  True),
    StructField("age",        IntegerType(), True),
    StructField("join_date",  DateType(),    True),
    StructField("is_active",  BooleanType(), True),
])

df = spark.read \
    .schema(schema) \
    .option("header", "true") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv("file.csv")
```

### DDL string — shortcut

```python
schema = "emp_id INT, name STRING, department STRING, salary DOUBLE, age INT, join_date DATE, is_active BOOLEAN"
df = spark.read.schema(schema).csv("file.csv", header=True)
```

### Comparison

| | inferSchema | StructType / DDL |
|---|---|---|
| Speed | Slow (reads twice) | Fast (reads once) |
| Type control | Auto-guessed | Exact |
| Bad value handling | May silently mis-cast | Becomes NULL (PERMISSIVE) |
| When to use | Exploration | Production |

### Common PySpark types

| Type | Class | Use for |
|---|---|---|
| String | `StringType()` | Text |
| Integer | `IntegerType()` | Whole numbers (32-bit) |
| Long | `LongType()` | Large whole numbers (64-bit) |
| Double | `DoubleType()` | Decimal numbers (64-bit float) |
| Boolean | `BooleanType()` | true / false |
| Date | `DateType()` | Date only (yyyy-MM-dd) |
| Timestamp | `TimestampType()` | Date + time |

---

## 9. Reading Multiple CSV Files

```python
from pyspark.sql.functions import input_file_name

# List of specific files — works on ALL platforms
df = spark.read.csv(["file1.csv", "file2.csv"], header=True)

# Whole folder — Linux/Mac/Databricks only
df = spark.read.csv("data/", header=True)

# Wildcard — Linux/Mac/Databricks only
df = spark.read.csv("data/employees_*.csv", header=True)

# Trace which file each row came from
df = spark.read.csv(["file1.csv", "file2.csv"], header=True) \
    .withColumn("source_file", input_file_name())
```

---

## 10. Write Modes

```python
df.write.mode("overwrite").option("header", "true").csv("output/folder")
```

| Mode | Behavior |
|---|---|
| `overwrite` | Delete existing data and write fresh |
| `append` | Add to existing data |
| `ignore` | Do nothing if path already exists |
| `error` | Throw exception if path exists (default) |

Spark writes a **folder**, not a single file. Inside: one `part-*.csv` per partition.

---

## 11. CSV Options Reference

| Option | Default | What it does |
|---|---|---|
| `header` | `false` | First row is column names |
| `inferSchema` | `false` | Auto-detect column types |
| `sep` | `,` | Column delimiter |
| `nullValue` | `""` | String treated as NULL |
| `dateFormat` | `yyyy-MM-dd` | Parse date columns |
| `timestampFormat` | ISO 8601 | Parse timestamp columns |
| `multiLine` | `false` | Allow values spanning multiple lines |
| `mode` | `PERMISSIVE` | How to handle bad rows |
| `quote` | `"` | Quote character |
| `escape` | `\` | Escape character inside quotes |
| `ignoreLeadingWhiteSpace` | `false` | Strip leading spaces |
| `ignoreTrailingWhiteSpace` | `false` | Strip trailing spaces |
| `encoding` | `UTF-8` | File character encoding |
