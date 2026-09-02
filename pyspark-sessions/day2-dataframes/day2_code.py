"""
Day 2 - DataFrame Operations in PySpark
Topics: select, filter/where, withColumn, groupBy+agg, orderBy,
        explain (lazy evaluation), toPandas, col(), lit(), alias()
"""

import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

os.environ['JAVA_HOME']             = 'C:/Program Files/DBeaver/jre'
os.environ['PYSPARK_PYTHON']        = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'
os.environ['PYSPARK_DRIVER_PYTHON'] = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Day2 - DataFrame Operations") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.ui.showConsoleProgress", "false") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")

print("=" * 60)
print("Day 2 - DataFrame Operations")
print("=" * 60)

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

print("\n--- Base DataFrame ---")
df.show()


# =============================================================
# SECTION 1 - select
# =============================================================
# Select returns a NEW DataFrame with only the specified columns.
# DataFrames are IMMUTABLE - the original df is never changed.
#
# Two styles:
#   string name  - simple column pick
#   col()        - allows expressions, arithmetic, renaming

from pyspark.sql.functions import col

print("\n--- 1A: select by column name strings ---")
df.select("name", "salary").show()

print("\n--- 1B: select using col() with expression ---")
df.select(
    col("name"),
    col("salary"),
    (col("salary") * 1.1).alias("salary_10pct_hike")
).show()

print("\n--- 1C: select all columns + a derived one ---")
df.select("*", (col("salary") / 83).cast("int").alias("salary_usd")).show()


# =============================================================
# SECTION 2 - filter / where
# =============================================================
# filter() and where() are identical - both filter rows.
# Use col() expressions with comparison operators.
#
# IMPORTANT: use & for AND, | for OR, ~ for NOT
#            NOT Python's 'and' / 'or' / 'not'
# Wrap each condition in parentheses when combining.

print("\n--- 2A: filter - single condition ---")
df.filter(col("salary") > 65000).show()

print("\n--- 2B: where - same as filter ---")
df.where(col("department") == "Engineering").show()

print("\n--- 2C: filter - AND condition ---")
df.filter(
    (col("department") == "Engineering") & (col("salary") > 80000)
).show()

print("\n--- 2D: filter - OR condition ---")
df.filter(
    (col("department") == "HR") | (col("age") < 27)
).show()

print("\n--- 2E: filter - isin() ---")
df.filter(col("department").isin("Engineering", "HR")).show()

print("\n--- 2F: filter - isNull() / isNotNull() ---")
from pyspark.sql.functions import lit
df_with_null = df.withColumn("bonus", lit(None).cast("int"))
df_with_null.filter(col("bonus").isNull()).show()


# =============================================================
# SECTION 3 - withColumn
# =============================================================
# withColumn(name, expression)
#   If name exists   -> replaces the column
#   If name is new   -> adds a new column
#
# Commonly used imports: col, lit, upper, lower, round, cast

from pyspark.sql.functions import upper, lower, round as spark_round

print("\n--- 3A: withColumn - add new column ---")
df.withColumn("salary_usd", (col("salary") / 83).cast("int")).show()

print("\n--- 3B: withColumn - replace existing column (uppercase) ---")
df.withColumn("department", upper(col("department"))).show()

print("\n--- 3C: withColumn - add a constant column using lit() ---")
df.withColumn("country", lit("India")).show()

print("\n--- 3D: withColumn - cast column type ---")
df.withColumn("salary", col("salary").cast("double")).printSchema()

print("\n--- 3E: withColumn - conditional column using when/otherwise ---")
from pyspark.sql.functions import when
df.withColumn(
    "level",
    when(col("salary") >= 80000, "Senior")
    .when(col("salary") >= 60000, "Mid")
    .otherwise("Junior")
).show()


# =============================================================
# SECTION 4 - groupBy + aggregation
# =============================================================
# groupBy returns a GroupedData object - must follow with agg().
#
# Common aggregate functions: count, avg, sum, min, max
# Use .agg() to apply multiple aggregations at once.

from pyspark.sql.functions import count, avg, sum as spark_sum, min as spark_min, max as spark_max

print("\n--- 4A: groupBy - count per department ---")
df.groupBy("department").count().show()

print("\n--- 4B: groupBy - average salary ---")
df.groupBy("department").agg(
    avg("salary").alias("avg_salary")
).show()

print("\n--- 4C: groupBy - multiple aggregations ---")
df.groupBy("department").agg(
    count("*").alias("headcount"),
    avg("salary").alias("avg_salary"),
    spark_max("salary").alias("max_salary"),
    spark_min("age").alias("youngest_age")
).show()

print("\n--- 4D: groupBy - round the result ---")
df.groupBy("department").agg(
    spark_round(avg("salary"), 2).alias("avg_salary_rounded")
).show()


# =============================================================
# SECTION 5 - orderBy / sort
# =============================================================
# orderBy and sort are the same.
# Use .asc() for ascending (default), .desc() for descending.
# Pass multiple columns to sort by secondary criteria.

print("\n--- 5A: orderBy - salary descending ---")
df.orderBy(col("salary").desc()).show()

print("\n--- 5B: orderBy - department ASC, salary DESC ---")
df.orderBy(col("department").asc(), col("salary").desc()).show()

print("\n--- 5C: orderBy - using string shorthand ---")
df.orderBy("department", "salary").show()   # both ascending by default


# =============================================================
# SECTION 6 - Lazy evaluation and explain()
# =============================================================
# Transformations (select, filter, withColumn, groupBy) are LAZY.
# They only build a logical plan - no data is processed yet.
# An ACTION (show, count, collect, write) triggers execution.
#
# explain() prints the physical plan Spark will execute.
# Use it to understand what Spark actually does under the hood.

print("\n--- 6A: Build a lazy plan (no execution yet) ---")
plan = df \
    .filter(col("age") > 28) \
    .withColumn("seniority", lit("Senior")) \
    .select("name", "department", "salary", "seniority")

print("Plan object created - nothing executed yet")

print("\n--- 6B: explain() - view the physical plan ---")
plan.explain()

print("\n--- 6C: show() triggers execution of the full plan ---")
plan.show()


# =============================================================
# SECTION 7 - toPandas
# =============================================================
# .toPandas() collects ALL rows to the driver as a Pandas DataFrame.
# Only use on small DataFrames - this defeats distributed computing
# for large data.
#
# Useful for: final display, plotting, exporting small results.

print("\n--- 7: toPandas - collect filtered result to driver ---")
pandas_df = df.filter(col("department") == "Engineering").toPandas()
print(pandas_df)
print(f"\nType: {type(pandas_df)}")


# =============================================================
# SECTION 8 - rename and drop columns
# =============================================================

print("\n--- 8A: withColumnRenamed ---")
df.withColumnRenamed("name", "employee_name").show()

print("\n--- 8B: drop column ---")
df.drop("age").show()

print("\n--- 8C: select with alias (another way to rename) ---")
df.select(
    col("name").alias("employee_name"),
    col("department").alias("dept"),
    col("salary")
).show()


# =============================================================
# SUMMARY OF IMPORTS USED TODAY
# =============================================================
# from pyspark.sql import SparkSession                   -- always needed
# from pyspark.sql.functions import col                  -- column expressions
# from pyspark.sql.functions import lit                  -- constant column
# from pyspark.sql.functions import upper, lower         -- string functions
# from pyspark.sql.functions import when                 -- conditional logic
# from pyspark.sql.functions import count, avg, sum,
#                                   min, max, round      -- aggregations

print("\n" + "=" * 60)
print("Day 2 Complete")
print("=" * 60)

spark.stop()
print("SparkSession stopped. Done.")
