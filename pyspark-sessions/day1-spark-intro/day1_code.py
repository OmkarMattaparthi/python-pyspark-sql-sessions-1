"""
Day 1 — First PySpark Script
Topics: SparkSession, createDataFrame, read CSV, show, printSchema,
        select, filter, withColumn, groupBy, count, stop
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, upper, lit, avg, count

# =============================================================
# 1. Create a SparkSession
# =============================================================
# SparkSession is the single entry point to all Spark functionality.
# .master("local[*]") → run locally using ALL available CPU cores.
# Use local[2] to use exactly 2 cores, local[1] for single-threaded.
# .getOrCreate()     → returns existing session if one already exists.

spark = SparkSession.builder \
    .appName("Day1 - PySpark Intro") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .getOrCreate()

# Suppress INFO logs — only show warnings and errors
spark.sparkContext.setLogLevel("WARN")

print("=" * 60)
print("SparkSession created")
print(f"Spark version : {spark.version}")
print(f"App name      : {spark.sparkContext.appName}")
print("=" * 60)


# =============================================================
# 2. Create a DataFrame from Python data (in-memory)
# =============================================================
# createDataFrame takes a list of tuples + list of column names.
# This is the fastest way to create small test DataFrames.

data = [
    ("Alice",   "Engineering",  85000, 30),
    ("Bob",     "Sales",        60000, 25),
    ("Carol",   "Engineering",  92000, 35),
    ("Dave",    "Sales",        58000, 28),
    ("Eve",     "HR",           55000, 32),
    ("Frank",   "Engineering",  78000, 40),
    ("Grace",   "HR",           61000, 29),
    ("Hank",    "Sales",        67000, 45),
]

columns = ["name", "department", "salary", "age"]

df = spark.createDataFrame(data, columns)

print("\n--- Original DataFrame ---")
df.show()


# =============================================================
# 3. printSchema — understand column names and data types
# =============================================================
# Always run printSchema() first when working with a new dataset.
# Shows the tree of column name → data type → nullable flag.

print("--- Schema ---")
df.printSchema()


# =============================================================
# 4. Basic inspection
# =============================================================

print(f"Row count  : {df.count()}")
print(f"Column count: {len(df.columns)}")
print(f"Columns    : {df.columns}")


# =============================================================
# 5. select — choose specific columns
# =============================================================
# Spark does NOT modify the original df (DataFrames are immutable).
# Every transformation returns a NEW DataFrame.

print("\n--- select: name and salary only ---")
df.select("name", "salary").show()

# You can also use col() for expressions:
print("--- select using col() ---")
df.select(col("name"), col("salary") * 1.1).show()


# =============================================================
# 6. filter / where — row filtering (equivalent, pick either)
# =============================================================

print("--- filter: salary > 65000 ---")
df.filter(col("salary") > 65000).show()

print("--- filter: Engineering department ---")
df.filter(col("department") == "Engineering").show()

# Combining conditions: use & (AND) | (OR) instead of and/or
print("--- filter: Engineering AND salary > 80000 ---")
df.filter((col("department") == "Engineering") & (col("salary") > 80000)).show()


# =============================================================
# 7. withColumn — add or replace a column
# =============================================================
# First argument: column name (new or existing).
# Second argument: the expression for the column's value.

print("--- withColumn: add salary_usd (salary / 83 as USD approximation) ---")
df_with_usd = df.withColumn("salary_usd", (col("salary") / 83).cast("int"))
df_with_usd.show()

print("--- withColumn: uppercase department ---")
df_upper = df.withColumn("department", upper(col("department")))
df_upper.show()

print("--- withColumn: add a constant column ---")
df_const = df.withColumn("country", lit("India"))
df_const.show()


# =============================================================
# 8. groupBy + aggregation
# =============================================================
# groupBy returns a GroupedData object.
# You must follow it with an aggregation: agg(), count(), avg(), sum(), etc.

print("--- groupBy department → count ---")
df.groupBy("department").count().show()

print("--- groupBy department → average salary ---")
df.groupBy("department").agg(avg("salary").alias("avg_salary")).show()

print("--- groupBy department → count + avg salary ---")
df.groupBy("department") \
  .agg(
      count("*").alias("headcount"),
      avg("salary").alias("avg_salary")
  ) \
  .show()


# =============================================================
# 9. orderBy — sort results
# =============================================================

print("--- orderBy salary DESC ---")
df.orderBy(col("salary").desc()).show()

print("--- orderBy department ASC, salary DESC ---")
df.orderBy(col("department").asc(), col("salary").desc()).show()


# =============================================================
# 10. Understanding lazy evaluation — nothing runs until an action
# =============================================================
# The lines below build up a plan — NO computation happens:

plan = df \
    .filter(col("age") > 28) \
    .withColumn("seniority", lit("Senior")) \
    .select("name", "department", "salary", "seniority")

# explain() shows the execution plan Spark built
print("--- Execution plan (explain) ---")
plan.explain()

# .show() is the action that triggers the plan to actually run
print("--- Result after running the plan ---")
plan.show()


# =============================================================
# 11. Read a CSV file (most common real-world usage)
# =============================================================
# Uncommnet and adjust the path to run this section.
# header=True       → first row is column names
# inferSchema=True  → Spark scans the file to detect types (slower)

# df_csv = spark.read.csv(
#     "path/to/your/file.csv",
#     header=True,
#     inferSchema=True
# )
# df_csv.show(5)
# df_csv.printSchema()


# =============================================================
# 12. Convert to Pandas (for small results)
# =============================================================
# .toPandas() collects ALL data to the Driver — only safe for small DataFrames.

pandas_df = df.filter(col("department") == "Engineering").toPandas()
print("\n--- Converted to Pandas ---")
print(pandas_df)
print(type(pandas_df))


# =============================================================
# 13. Stop the SparkSession
# =============================================================
# Always stop Spark at the end of your script.
# This releases resources and shuts down the Spark UI on port 4040.

spark.stop()
print("\nSparkSession stopped. Done.")
