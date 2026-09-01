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

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, explode, explode_outer,
    from_json, to_json, get_json_object, json_tuple,
    regexp_extract, split, input_file_name
)
from pyspark.sql.types import (
    StructType, StructField,
    IntegerType, StringType, DoubleType, BooleanType,
    DateType, ArrayType, MapType
)

# -------------------------------------------------------
# Sample data files used in this session (inside data/)
# -------------------------------------------------------
# employees.csv          - standard CSV with header
# employees_no_header.csv - no header row
# employees_pipe.csv     - pipe (|) separator
# employees_dirty.csv    - missing/bad values
# employees_multiline.csv - values spanning multiple lines
# employees_flat.json    - one JSON object per line (JSONL)
# employees_nested.json  - nested struct + array fields
# employees_array.json   - whole file is a JSON array
# orders.json            - nested array of items per order
# logs.txt               - raw log lines (unstructured)
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
# inferSchema=True makes Spark scan the file to detect types.
# header=True uses the first row as column names.

print("\n--- 1A: CSV with header + inferSchema ---")
df_infer = spark.read.csv(
    f"{DATA}/employees.csv",
    header=True,
    inferSchema=True
)
df_infer.show()
df_infer.printSchema()
# Notice: salary=long, age=int, is_active=boolean, join_date=date


# =============================================================
# SECTION 2 - READ CSV: all options via .option()
# =============================================================
# You can chain .option() calls or pass a dict to .options()

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

print("\n--- 2B: CSV - passing options as dict ---")
df_opts2 = spark.read \
    .options(header="true", inferSchema="true", nullValue="N/A") \
    .csv(f"{DATA}/employees.csv")
df_opts2.show(5)


# =============================================================
# SECTION 3 - READ CSV: no header (assign column names manually)
# =============================================================

print("\n--- 3: CSV with no header row ---")
df_no_hdr = spark.read.csv(
    f"{DATA}/employees_no_header.csv",
    header=False,
    inferSchema=True
)
# Columns get auto-named _c0, _c1, _c2 ...
df_no_hdr.show()

# Rename columns after reading
df_no_hdr = df_no_hdr.toDF("emp_id", "name", "department", "salary", "age", "join_date", "is_active")
print("After renaming columns:")
df_no_hdr.show()


# =============================================================
# SECTION 4 - READ CSV: custom delimiter (pipe)
# =============================================================

print("\n--- 4: CSV with pipe (|) separator ---")
df_pipe = spark.read.csv(
    f"{DATA}/employees_pipe.csv",
    header=True,
    inferSchema=True,
    sep="|"          # sep= is shorthand for .option("sep", "|")
)
df_pipe.show()


# =============================================================
# SECTION 5 - READ CSV: multiline values
# =============================================================
# When a field value contains a newline, set multiLine=True.
# Without it Spark treats each line as a separate row and breaks the parse.

print("\n--- 5: CSV with multiline values ---")
df_multi = spark.read.csv(
    f"{DATA}/employees_multiline.csv",
    header=True,
    inferSchema=True,
    multiLine=True,
    quote='"',       # double-quote wraps multiline values
    escape='"'
)
df_multi.show(truncate=False)


# =============================================================
# SECTION 6 - READ CSV: dirty data and parse modes
# =============================================================
# employees_dirty.csv has: missing emp_id, missing name, "N/A" salary

print("\n--- 6A: Dirty CSV - PERMISSIVE mode (default) ---")
# Bad values become NULL. No rows are dropped.
df_dirty = spark.read.csv(
    f"{DATA}/employees_dirty.csv",
    header=True,
    inferSchema=True,
    nullValue="N/A"
)
df_dirty.show()

print("\n--- 6B: Dirty CSV - DROPMALFORMED mode ---")
# Rows that cannot be parsed at all are silently dropped.
df_drop = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("mode", "DROPMALFORMED") \
    .csv(f"{DATA}/employees_dirty.csv")
df_drop.show()

print("\n--- 6C: Dirty CSV - FAILFAST mode (raises error on first bad row) ---")
# Uncomment to see the exception - useful in production to catch data issues early
# df_fail = spark.read \
#     .option("header", "true") \
#     .option("inferSchema", "true") \
#     .option("mode", "FAILFAST") \
#     .csv(f"{DATA}/employees_dirty.csv")
# df_fail.show()
print("    (FAILFAST example commented out - it raises an exception on dirty data)")


# =============================================================
# SECTION 7 - DEFINED SCHEMA (StructType)
# =============================================================
# Explicit schema: faster (one file pass), type-safe, production-ready.

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
# DDL string is quicker to write - same result as StructType
ddl_schema = "emp_id INT, name STRING, department STRING, salary DOUBLE, age INT, join_date DATE, is_active BOOLEAN"

df_ddl = spark.read \
    .schema(ddl_schema) \
    .option("header", "true") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv(f"{DATA}/employees.csv")
df_ddl.show()
df_ddl.printSchema()

print("\n--- 7C: Schema with no header (column order matters) ---")
schema_no_hdr = "emp_id INT, name STRING, department STRING, salary DOUBLE, age INT, join_date DATE, is_active BOOLEAN"
df_schema_nohdr = spark.read \
    .schema(schema_no_hdr) \
    .option("header", "false") \
    .csv(f"{DATA}/employees_no_header.csv")
df_schema_nohdr.show()


# =============================================================
# SECTION 8 - READ JSON: flat JSONL (one object per line)
# =============================================================
# Default Spark JSON format - each line is a separate JSON object.
# Schema is inferred automatically from the JSON keys.

print("\n--- 8A: Flat JSONL - inferSchema (automatic) ---")
df_json = spark.read.json(f"{DATA}/employees_flat.json")
df_json.show()
df_json.printSchema()

print("\n--- 8B: Flat JSONL - with explicit schema ---")
json_schema = StructType([
    StructField("emp_id",     IntegerType(), True),
    StructField("name",       StringType(),  True),
    StructField("department", StringType(),  True),
    StructField("salary",     DoubleType(),  True),
    StructField("age",        IntegerType(), True),
    StructField("join_date",  StringType(),  True),  # keep as string, parse later
    StructField("is_active",  BooleanType(), True),
])
df_json_schema = spark.read.schema(json_schema).json(f"{DATA}/employees_flat.json")
df_json_schema.show()

print("\n--- 8C: JSON options - primitivesAsString ---")
# Forces ALL values (numbers, booleans) to be read as strings.
# Useful when you want to delay type casting.
df_str = spark.read \
    .option("primitivesAsString", "true") \
    .json(f"{DATA}/employees_flat.json")
df_str.show()
df_str.printSchema()  # all columns will be StringType


# =============================================================
# SECTION 9 - READ JSON: multi-line (whole file is a JSON array)
# =============================================================
# employees_array.json contains a JSON array [...] spanning multiple lines.
# Without multiLine=True, Spark will fail or produce wrong results.

print("\n--- 9: Multi-line JSON array ---")
df_array = spark.read \
    .option("multiLine", "true") \
    .json(f"{DATA}/employees_array.json")
df_array.show()
df_array.printSchema()


# =============================================================
# SECTION 10 - READ JSON: nested struct + array fields
# =============================================================
# employees_nested.json has:
#   address: {city, state, pincode}  -> becomes a StructType column
#   skills:  ["Python", "Spark"]     -> becomes an ArrayType column

print("\n--- 10A: Nested JSON - read as-is ---")
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

print("\n--- 10C: explode array column - one row per skill ---")
# explode turns ["Python", "Spark", "SQL"] into 3 separate rows
df_nested.select(
    col("name"),
    col("department"),
    explode(col("skills")).alias("skill")
).show()

print("\n--- 10D: explode_outer - keeps rows even if array is null/empty ---")
df_nested.select(
    col("name"),
    explode_outer(col("skills")).alias("skill")
).show()


# =============================================================
# SECTION 11 - READ JSON: deeply nested with arrays of structs
# =============================================================
# orders.json has items: [{product, qty, price}, ...]
# After explode, each item becomes a row with order context.

print("\n--- 11A: Orders JSON - deeply nested array of structs ---")
df_orders = spark.read.json(f"{DATA}/orders.json")
df_orders.show(truncate=False)
df_orders.printSchema()

print("\n--- 11B: Explode items array and access struct fields ---")
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

print("\n--- 11C: to_json - convert struct column back to JSON string ---")
df_orders.select(
    col("order_id"),
    col("customer"),
    to_json(col("items")).alias("items_json_string")
).show(truncate=False)


# =============================================================
# SECTION 12 - PARSE JSON from a STRING column
# =============================================================
# Common in real data: a column contains JSON text as a string.
# Use from_json() to parse it into a struct.

print("\n--- 12A: from_json - parse JSON string column into struct ---")
# Simulate a DataFrame where one column holds JSON as a string
raw_data = [
    (1, '{"city": "Bangalore", "pincode": "560001"}'),
    (2, '{"city": "Mumbai", "pincode": "400001"}'),
    (3, '{"city": "Hyderabad", "pincode": "500001"}'),
]
df_raw = spark.createDataFrame(raw_data, ["emp_id", "address_json"])

# Define schema of the JSON inside the string
addr_schema = StructType([
    StructField("city",    StringType(), True),
    StructField("pincode", StringType(), True),
])

df_parsed = df_raw.withColumn("address", from_json(col("address_json"), addr_schema))
df_parsed.show()
df_parsed.printSchema()

# Now access nested fields
df_parsed.select(
    col("emp_id"),
    col("address.city").alias("city"),
    col("address.pincode").alias("pincode")
).show()

print("\n--- 12B: get_json_object - extract single field from JSON string ---")
# Faster than from_json when you need just one field.
# Uses JSONPath syntax: $.field or $.nested.field
df_raw.select(
    col("emp_id"),
    get_json_object(col("address_json"), "$.city").alias("city"),
    get_json_object(col("address_json"), "$.pincode").alias("pincode")
).show()

print("\n--- 12C: json_tuple - extract multiple fields in one call ---")
# More concise than multiple get_json_object calls
df_raw.select(
    col("emp_id"),
    json_tuple(col("address_json"), "city", "pincode").alias("city", "pincode")
).show()


# =============================================================
# SECTION 13 - READ TEXT FILE (logs)
# =============================================================
# spark.read.text() reads each line as a single "value" column.
# Then use regexp_extract / split to parse the structure.

print("\n--- 13A: Read raw text file ---")
df_text = spark.read.text(f"{DATA}/logs.txt")
df_text.show(truncate=False)
df_text.printSchema()  # one column: value (StringType)

print("\n--- 13B: Parse log lines with regexp_extract ---")
# Log format: "2024-01-15 08:00:01 INFO  UserLogin ..."
df_logs = df_text.select(
    regexp_extract(col("value"), r"^(\d{4}-\d{2}-\d{2})", 1).alias("log_date"),
    regexp_extract(col("value"), r"^\S+ (\S+)", 1).alias("log_time"),
    regexp_extract(col("value"), r"^\S+ \S+ (\S+)", 1).alias("log_level"),
    regexp_extract(col("value"), r"^\S+ \S+ \S+\s+(\S+)", 1).alias("event"),
    col("value").alias("raw_line")
)
df_logs.show(truncate=False)

print("\n--- 13C: Filter logs by level ---")
df_logs.filter(col("log_level") == "ERROR").show(truncate=False)
df_logs.filter(col("log_level").isin("ERROR", "WARN")).show(truncate=False)


# =============================================================
# SECTION 14 - READ MULTIPLE FILES
# =============================================================
# NOTE: Reading a whole folder or using wildcards requires winutils on Windows.
# We use explicit file lists here which work without it.
# On Linux/Mac/Databricks the folder and wildcard paths work natively.

print("\n--- 14A: Read a whole folder ---")
# On Linux/Mac/Databricks:
#   spark.read.csv("data/", header=True, inferSchema=True)
# On Windows (without winutils), pass explicit files instead:
print("    Folder read example (Linux/Mac/Databricks):")
print("    spark.read.csv('data/', header=True, inferSchema=True)")
print("    On Windows without winutils - use explicit file list (see 14C)")

print("\n--- 14B: Wildcard pattern (Linux/Mac/Databricks) ---")
# On Linux/Mac/Databricks:
#   spark.read.csv("data/employees_*.csv", header=True, inferSchema=True)
# On Windows without winutils - pass a list instead.
print("    Wildcard example (Linux/Mac/Databricks):")
print("    spark.read.csv('data/employees_*.csv', header=True, inferSchema=True)")

print("\n--- 14C: List of specific files (works on all platforms) ---")
df_list = spark.read.csv(
    [f"{DATA}/employees.csv", f"{DATA}/employees_no_header.csv"],
    header=True,
    inferSchema=True
)
print(f"Rows from file list: {df_list.count()}")
df_list.show(5)

print("\n--- 14D: Add source filename column ---")
# input_file_name() returns the full path of the file each row came from.
# Very useful when reading multiple files to trace which file a row is from.
df_with_source = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv([f"{DATA}/employees.csv", f"{DATA}/employees_no_header.csv"]) \
    .withColumn("source_file", input_file_name())
df_with_source.select("emp_id", "name", "source_file").show(10, truncate=False)


# =============================================================
# SECTION 15 - WRITE FILES (reference - works on Linux/Mac/Databricks)
# =============================================================
# Writing files requires the native Hadoop library on Windows.
# On Linux/Mac/Databricks these work without any extra setup.

print("\n--- 15: Write reference (run on Linux/Mac/Databricks) ---")
print("    CSV  : df.write.mode('overwrite').option('header','true').csv('output/folder')")
print("    JSON : df.write.mode('overwrite').json('output/folder')")
print("    Parquet: df.write.mode('overwrite').parquet('output/folder')")
print("    Note: Spark always writes a FOLDER, not a single file.")
print("          One part-*.csv / part-*.json file is created per partition.")
print("    Write modes: overwrite | append | ignore | error(default)")

# Uncomment on Linux/Mac/Databricks:
# df_schema.write.mode("overwrite").option("header", "true") \
#     .csv("pyspark-sessions/day2-reading-files/output/employees_csv")
# df_nested.write.mode("overwrite") \
#     .json("pyspark-sessions/day2-reading-files/output/employees_json")


# =============================================================
# SUMMARY
# =============================================================
print("\n" + "=" * 60)
print("Day 2 Summary")
print("=" * 60)
print("CSV reading    : header, inferSchema, sep, nullValue,")
print("                 multiLine, PERMISSIVE/DROPMALFORMED/FAILFAST")
print("Schema options : StructType, DDL string, inferSchema")
print("JSON reading   : JSONL, multiLine array, nested struct,")
print("                 array explode, from_json, get_json_object")
print("Text reading   : spark.read.text + regexp_extract")
print("Multi-file     : folder, wildcard, list, input_file_name()")
print("Write          : mode=overwrite/append/ignore/error")
print("=" * 60)

spark.stop()
print("\nSparkSession stopped. Done.")
