"""
Day 2 - Reading Files in PySpark
Topics: CSV (all options), JSON (flat/nested/array/string), text files,
        inferSchema vs defined schema, DDL schema, multiLine, parse modes,
        nested struct access, explode, from_json, multiple files
"""

import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

os.environ['JAVA_HOME']             = 'C:/Program Files/DBeaver/jre'
os.environ['PYSPARK_PYTHON']        = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'
os.environ['PYSPARK_DRIVER_PYTHON'] = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'

# SparkSession is the only import needed before the session starts
from pyspark.sql import SparkSession

# -------------------------------------------------------
# Sample data files used in this session (inside data/)
# -------------------------------------------------------
# employees.csv           - standard CSV with header
# employees_no_header.csv - no header row
# employees_pipe.csv      - pipe (|) separator
# employees_dirty.csv     - missing/bad values
# employees_multiline.csv - values spanning multiple lines
# employees_flat.json     - one JSON object per line (JSONL)
# employees_nested.json   - nested struct + array fields
# employees_array.json    - whole file is a JSON array
# orders.json             - nested array of items per order
# logs.txt                - raw log lines (unstructured)
# -------------------------------------------------------

spark = SparkSession.builder \
    .appName("Day2 - Reading Files") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.ui.showConsoleProgress", "false") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")

DATA = "pyspark-sessions/day2-reading-files/data"

print("=" * 60)
print("Day 2 - Reading Files in PySpark")
print("=" * 60)


# =============================================================
# SECTION 1 - READ CSV: basic with inferSchema
# =============================================================
# New import: nothing extra — spark.read is built into SparkSession
#
# inferSchema=True  -> Spark reads the file twice to detect column types
# header=True       -> first row becomes column names

print("\n--- 1A: CSV with header + inferSchema ---")
df_infer = spark.read.csv(
    f"{DATA}/employees.csv",
    header=True,
    inferSchema=True
)
df_infer.show()
df_infer.printSchema()


# =============================================================
# SECTION 2 - READ CSV: .option() and .options() styles
# =============================================================
# New import: nothing extra
#
# Two ways to pass options:
#   .option("key", "value")          - chain one at a time
#   .options(key="value", key2="v2") - pass all at once as kwargs

print("\n--- 2A: CSV - chaining .option() calls ---")
df_opts = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("dateFormat", "yyyy-MM-dd") \
    .option("nullValue", "N/A") \
    .option("ignoreLeadingWhiteSpace", "true") \
    .option("ignoreTrailingWhiteSpace", "true") \
    .csv(f"{DATA}/employees.csv")
df_opts.show(5)

print("\n--- 2B: CSV - passing all options as kwargs to .options() ---")
df_opts2 = spark.read \
    .options(header="true", inferSchema="true", nullValue="N/A") \
    .csv(f"{DATA}/employees.csv")
df_opts2.show(5)


# =============================================================
# SECTION 3 - READ CSV: no header row
# =============================================================
# New import: nothing extra
#
# When header=False, Spark names columns _c0, _c1, _c2 ...
# Use .toDF() to assign proper names after reading.

print("\n--- 3: CSV with no header row ---")
df_no_hdr = spark.read.csv(
    f"{DATA}/employees_no_header.csv",
    header=False,
    inferSchema=True
)
print("Auto-named columns (_c0, _c1 ...):")
df_no_hdr.show()

df_no_hdr = df_no_hdr.toDF("emp_id", "name", "department", "salary", "age", "join_date", "is_active")
print("After renaming with .toDF():")
df_no_hdr.show()


# =============================================================
# SECTION 4 - READ CSV: custom delimiter
# =============================================================
# New import: nothing extra
#
# sep= sets the column separator. Default is comma.
# Use sep="|" for pipe-delimited files, sep="\t" for TSV.

print("\n--- 4: CSV with pipe (|) separator ---")
df_pipe = spark.read.csv(
    f"{DATA}/employees_pipe.csv",
    header=True,
    inferSchema=True,
    sep="|"
)
df_pipe.show()


# =============================================================
# SECTION 5 - READ CSV: multiline values inside quotes
# =============================================================
# New import: nothing extra
#
# When a field value contains a newline character and is wrapped
# in quotes, set multiLine=True so Spark reads it as one value.

print("\n--- 5: CSV with multiline quoted values ---")
df_multi = spark.read.csv(
    f"{DATA}/employees_multiline.csv",
    header=True,
    inferSchema=True,
    multiLine=True,
    quote='"',
    escape='"'
)
df_multi.show(truncate=False)


# =============================================================
# SECTION 6 - READ CSV: dirty data and parse modes
# =============================================================
# New import: nothing extra
#
# Three modes for handling bad/corrupt rows:
#   PERMISSIVE   (default) - bad values become NULL, no rows dropped
#   DROPMALFORMED          - silently drops rows that cannot be parsed
#   FAILFAST               - throws an exception on first bad row

print("\n--- 6A: Dirty CSV - PERMISSIVE mode (default) ---")
df_dirty = spark.read.csv(
    f"{DATA}/employees_dirty.csv",
    header=True,
    inferSchema=True,
    nullValue="N/A"
)
df_dirty.show()

print("\n--- 6B: Dirty CSV - DROPMALFORMED mode ---")
df_drop = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("mode", "DROPMALFORMED") \
    .csv(f"{DATA}/employees_dirty.csv")
df_drop.show()

print("\n--- 6C: FAILFAST mode - raises exception on first bad row ---")
# Uncomment to see the exception in action
# df_fail = spark.read \
#     .option("header", "true") \
#     .option("inferSchema", "true") \
#     .option("mode", "FAILFAST") \
#     .csv(f"{DATA}/employees_dirty.csv")
# df_fail.show()
print("    (commented out - uncomment to see exception on dirty data)")


# =============================================================
# SECTION 7 - DEFINED SCHEMA: StructType and DDL string
# =============================================================
# New imports: StructType, StructField, and data type classes
#
# Why define schema explicitly?
#   - Faster: file is read only ONCE (inferSchema reads twice)
#   - Safer:  you control exact types (no guessing)
#   - Required in production pipelines

from pyspark.sql.types import (
    StructType, StructField,
    IntegerType, StringType, DoubleType, BooleanType, DateType
)

print("\n--- 7A: Defined schema using StructType ---")
emp_schema = StructType([
    StructField("emp_id",     IntegerType(), True),
    StructField("name",       StringType(),  True),
    StructField("department", StringType(),  True),
    StructField("salary",     DoubleType(),  True),
    StructField("age",        IntegerType(), True),
    StructField("join_date",  DateType(),    True),
    StructField("is_active",  BooleanType(), True),
])

df_schema = spark.read.schema(emp_schema).csv(
    f"{DATA}/employees.csv",
    header=True,
    dateFormat="yyyy-MM-dd"
)
df_schema.show()
df_schema.printSchema()

print("\n--- 7B: Defined schema using DDL string (shortcut) ---")
# SQL DDL string - shorter to write, same result as StructType above
ddl_schema = "emp_id INT, name STRING, department STRING, salary DOUBLE, age INT, join_date DATE, is_active BOOLEAN"

df_ddl = spark.read \
    .schema(ddl_schema) \
    .option("header", "true") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv(f"{DATA}/employees.csv")
df_ddl.show()
df_ddl.printSchema()

print("\n--- 7C: Defined schema with no header (column order matters!) ---")
schema_no_hdr = "emp_id INT, name STRING, department STRING, salary DOUBLE, age INT, join_date DATE, is_active BOOLEAN"
df_schema_nohdr = spark.read \
    .schema(schema_no_hdr) \
    .option("header", "false") \
    .csv(f"{DATA}/employees_no_header.csv")
df_schema_nohdr.show()


# =============================================================
# SECTION 8 - READ JSON: flat JSONL (one object per line)
# =============================================================
# New imports: reuse StructType, StructField, type classes from Section 7
#
# Spark's default JSON reader expects JSONL format:
#   one complete JSON object per line.
# Schema is inferred automatically from keys - columns sorted alphabetically.

print("\n--- 8A: Flat JSONL - inferSchema (automatic) ---")
df_json = spark.read.json(f"{DATA}/employees_flat.json")
df_json.show()
df_json.printSchema()

print("\n--- 8B: Flat JSONL - with explicit StructType schema ---")
json_schema = StructType([
    StructField("emp_id",     IntegerType(), True),
    StructField("name",       StringType(),  True),
    StructField("department", StringType(),  True),
    StructField("salary",     DoubleType(),  True),
    StructField("age",        IntegerType(), True),
    StructField("join_date",  StringType(),  True),
    StructField("is_active",  BooleanType(), True),
])
df_json_schema = spark.read.schema(json_schema).json(f"{DATA}/employees_flat.json")
df_json_schema.show()

print("\n--- 8C: JSON option - primitivesAsString ---")
# Forces numbers and booleans to be read as strings.
# Useful when you want to delay casting or inspect raw values.
df_str = spark.read \
    .option("primitivesAsString", "true") \
    .json(f"{DATA}/employees_flat.json")
df_str.show()
df_str.printSchema()


# =============================================================
# SECTION 9 - READ JSON: multi-line (whole file is a JSON array)
# =============================================================
# New imports: nothing extra
#
# When the entire file is a JSON array [...] spanning multiple lines,
# set multiLine=True. Without it Spark reads each line independently
# and the [ ] brackets cause parse errors.

print("\n--- 9: Multi-line JSON array ---")
df_array = spark.read \
    .option("multiLine", "true") \
    .json(f"{DATA}/employees_array.json")
df_array.show()
df_array.printSchema()


# =============================================================
# SECTION 10 - READ JSON: nested struct and array fields
# =============================================================
# New imports: col, explode, explode_outer
#
# Spark automatically maps:
#   JSON object  {"city": ...}    -> StructType column
#   JSON array   ["Python", ...]  -> ArrayType column
#
# Access struct fields with dot notation: col("address.city")
# Flatten array columns with explode()

from pyspark.sql.functions import col, explode, explode_outer

print("\n--- 10A: Nested JSON - read as-is, see schema ---")
df_nested = spark.read.json(f"{DATA}/employees_nested.json")
df_nested.show(truncate=False)
df_nested.printSchema()

print("\n--- 10B: Access nested struct field with dot notation ---")
df_nested.select(
    col("name"),
    col("address.city").alias("city"),
    col("address.state").alias("state"),
    col("address.pincode").alias("pincode")
).show()

print("\n--- 10C: explode() - one row per array element ---")
# Each skill in the array becomes its own row.
# Rows with null/empty arrays are dropped by explode().
df_nested.select(
    col("name"),
    col("department"),
    explode(col("skills")).alias("skill")
).show()

print("\n--- 10D: explode_outer() - keeps rows even when array is null/empty ---")
# Same as explode but NULL array rows are kept (skill = NULL).
df_nested.select(
    col("name"),
    explode_outer(col("skills")).alias("skill")
).show()


# =============================================================
# SECTION 11 - READ JSON: array of structs (deeply nested)
# =============================================================
# New imports: to_json  (col, explode already imported in Section 10)
#
# orders.json has: items: [{product, qty, price}, ...]
# Pattern: explode the array -> select item.field to flatten each struct

from pyspark.sql.functions import to_json

print("\n--- 11A: Orders JSON - array of structs ---")
df_orders = spark.read.json(f"{DATA}/orders.json")
df_orders.show(truncate=False)
df_orders.printSchema()

print("\n--- 11B: Flatten - explode array then access struct fields ---")
df_orders_flat = df_orders.select(
    col("order_id"),
    col("customer"),
    col("status"),
    explode(col("items")).alias("item")
).select(
    col("order_id"),
    col("customer"),
    col("status"),
    col("item.product").alias("product"),
    col("item.qty").alias("qty"),
    col("item.price").alias("price")
)
df_orders_flat.show()

print("\n--- 11C: to_json() - convert a struct/array column back to JSON string ---")
df_orders.select(
    col("order_id"),
    col("customer"),
    to_json(col("items")).alias("items_json_string")
).show(truncate=False)


# =============================================================
# SECTION 12 - PARSE JSON from a STRING column
# =============================================================
# New imports: from_json, get_json_object, json_tuple
#
# Real-world scenario: a column in your table stores JSON as plain text.
# Three ways to extract fields from it:
#   from_json()         -> parse whole string into a struct (most powerful)
#   get_json_object()   -> extract one field using JSONPath (fastest for 1 field)
#   json_tuple()        -> extract multiple fields at once (concise)

from pyspark.sql.functions import from_json, get_json_object, json_tuple

print("\n--- 12A: from_json() - parse JSON string into a struct column ---")
raw_data = [
    (1, '{"city": "Bangalore", "pincode": "560001"}'),
    (2, '{"city": "Mumbai",    "pincode": "400001"}'),
    (3, '{"city": "Hyderabad", "pincode": "500001"}'),
]
df_raw = spark.createDataFrame(raw_data, ["emp_id", "address_json"])

addr_schema = StructType([
    StructField("city",    StringType(), True),
    StructField("pincode", StringType(), True),
])

df_parsed = df_raw.withColumn("address", from_json(col("address_json"), addr_schema))
df_parsed.show()
df_parsed.printSchema()

# After parsing - access fields with dot notation
df_parsed.select(
    col("emp_id"),
    col("address.city").alias("city"),
    col("address.pincode").alias("pincode")
).show()

print("\n--- 12B: get_json_object() - extract one field using JSONPath ---")
# Uses $.field syntax. Returns a string column.
# Best when you only need 1-2 fields and speed matters.
df_raw.select(
    col("emp_id"),
    get_json_object(col("address_json"), "$.city").alias("city"),
    get_json_object(col("address_json"), "$.pincode").alias("pincode")
).show()

print("\n--- 12C: json_tuple() - extract multiple fields in one call ---")
# Cleaner than multiple get_json_object calls.
# Returns all extracted fields as string columns.
df_raw.select(
    col("emp_id"),
    json_tuple(col("address_json"), "city", "pincode").alias("city", "pincode")
).show()


# =============================================================
# SECTION 13 - READ TEXT FILE (raw logs)
# =============================================================
# New imports: regexp_extract
#
# spark.read.text() reads the file as-is.
# Each line becomes one row in a single column called "value".
# Use regexp_extract() to pull structured fields out of each line.

from pyspark.sql.functions import regexp_extract

print("\n--- 13A: Read raw text file - each line is one 'value' row ---")
df_text = spark.read.text(f"{DATA}/logs.txt")
df_text.show(truncate=False)
df_text.printSchema()

print("\n--- 13B: Parse log lines with regexp_extract ---")
# Log format: "2024-01-15 08:00:01 INFO  EventName ..."
# regexp_extract(column, regex_pattern, group_number)
df_logs = df_text.select(
    regexp_extract(col("value"), r"^(\d{4}-\d{2}-\d{2})", 1).alias("log_date"),
    regexp_extract(col("value"), r"^\S+ (\S+)", 1).alias("log_time"),
    regexp_extract(col("value"), r"^\S+ \S+ (\S+)", 1).alias("log_level"),
    regexp_extract(col("value"), r"^\S+ \S+ \S+\s+(\S+)", 1).alias("event"),
    col("value").alias("raw_line")
)
df_logs.show(truncate=False)

print("\n--- 13C: Filter parsed logs by level ---")
df_logs.filter(col("log_level") == "ERROR").show(truncate=False)
df_logs.filter(col("log_level").isin("ERROR", "WARN")).show(truncate=False)


# =============================================================
# SECTION 14 - READ MULTIPLE FILES
# =============================================================
# New imports: input_file_name
#
# Spark can read multiple files in one call:
#   folder path   -> all files of that format in the folder
#   wildcard path -> files matching the pattern
#   list of paths -> specific files you name explicitly
#
# Note: folder and wildcard reads require native Hadoop on Windows.
# Explicit file lists work on all platforms.

from pyspark.sql.functions import input_file_name

print("\n--- 14A: Read a whole folder (Linux/Mac/Databricks) ---")
print("    spark.read.csv('data/', header=True, inferSchema=True)")
print("    -> reads ALL csv files in the folder as one DataFrame")

print("\n--- 14B: Wildcard pattern (Linux/Mac/Databricks) ---")
print("    spark.read.csv('data/employees_*.csv', header=True, inferSchema=True)")
print("    -> reads only files matching the pattern")

print("\n--- 14C: List of specific files (works on all platforms) ---")
df_list = spark.read.csv(
    [f"{DATA}/employees.csv", f"{DATA}/employees_no_header.csv"],
    header=True,
    inferSchema=True
)
print(f"Total rows from both files: {df_list.count()}")
df_list.show(5)

print("\n--- 14D: input_file_name() - add source file as a column ---")
# Tells you which file each row came from.
# Very useful when reading many files to trace data lineage.
df_with_source = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv([f"{DATA}/employees.csv", f"{DATA}/employees_no_header.csv"]) \
    .withColumn("source_file", input_file_name())
df_with_source.select("emp_id", "name", "source_file").show(10, truncate=False)


# =============================================================
# SECTION 15 - WRITE FILES (reference)
# =============================================================
# New imports: nothing extra - write is built into DataFrame
#
# Writing files requires native Hadoop on Windows.
# Works out of the box on Linux/Mac/Databricks.
#
# Spark always writes a FOLDER, not a single file.
# Inside the folder: one part-*.csv (or .json/.parquet) per partition.

print("\n--- 15: Write modes reference ---")
print("    overwrite : delete existing data and write fresh")
print("    append    : add to existing data")
print("    ignore    : do nothing if path already exists")
print("    error     : throw exception if path exists (default)")
print("")
print("    CSV     : df.write.mode('overwrite').option('header','true').csv('out/')")
print("    JSON    : df.write.mode('overwrite').json('out/')")
print("    Parquet : df.write.mode('overwrite').parquet('out/')")

# Uncomment on Linux/Mac/Databricks:
# df_schema.write.mode("overwrite").option("header", "true") \
#     .csv("pyspark-sessions/day2-reading-files/output/employees_csv")
# df_nested.write.mode("overwrite") \
#     .json("pyspark-sessions/day2-reading-files/output/employees_json")


# =============================================================
# SUMMARY OF IMPORTS USED TODAY
# =============================================================
# from pyspark.sql import SparkSession            -- always needed
#
# Section 7  : from pyspark.sql.types import StructType, StructField,
#                  IntegerType, StringType, DoubleType, BooleanType, DateType
#
# Section 10 : from pyspark.sql.functions import col, explode, explode_outer
#
# Section 11 : from pyspark.sql.functions import to_json
#
# Section 12 : from pyspark.sql.functions import from_json, get_json_object, json_tuple
#
# Section 13 : from pyspark.sql.functions import regexp_extract
#
# Section 14 : from pyspark.sql.functions import input_file_name

print("\n" + "=" * 60)
print("Day 2 Complete")
print("=" * 60)

spark.stop()
print("SparkSession stopped. Done.")
