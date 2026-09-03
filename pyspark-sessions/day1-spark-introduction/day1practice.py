"""
Day 1 - PySpark Setup & SparkSession
Topics: Environment setup, SparkSession creation, createDataFrame,
        printSchema, basic inspection
"""

import os
import sys

# Force UTF-8 output on Windows so print() never crashes on special chars
sys.stdout.reconfigure(encoding='utf-8')

# Must be set BEFORE importing pyspark - Spark reads these at import time.
# JAVA_HOME points to DBeaver's bundled JRE (Java 11) on this machine.
os.environ['JAVA_HOME']             = 'C:/Program Files/DBeaver/jre'
os.environ['PYSPARK_PYTHON']        = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'
os.environ['PYSPARK_DRIVER_PYTHON'] = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'

from pyspark.sql import SparkSession

# =============================================================
# 1. Create a SparkSession
# =============================================================
# SparkSession is the single entry point to all Spark functionality.
#
# .master("local[*]") - run locally using ALL available CPU cores.
#                       local[2] = exactly 2 cores, local[1] = single thread
# .appName(...)       - label shown in Spark UI (port 4040)
# .getOrCreate()      - returns existing session if one already exists
# spark.sql.shuffle.partitions - controls partitions after shuffle operations

spark = SparkSession.builder \
    .appName("Day1 - PySpark Intro") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.ui.showConsoleProgress", "false") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")

print("=" * 60)
print("SparkSession created")
print(f"Spark version : {spark.version}")
print(f"App name      : {spark.sparkContext.appName}")
print(f"Master        : {spark.sparkContext.master}")
print("=" * 60)


# =============================================================
# 2. Create a DataFrame from Python data (in-memory)
# =============================================================
# createDataFrame(data, schema)
#   data   - list of tuples (one tuple = one row)
#   schema - list of column name strings
#
# This is the fastest way to create small test DataFrames
# without needing any files.

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
# 3. printSchema - understand column names and data types
# =============================================================
# Always run printSchema() first when working with a new dataset.
# Shows: column name -> data type -> nullable flag.
# Spark inferred types from the Python values (str -> string, int -> long).

print("--- Schema ---")
df.printSchema()


# =============================================================
# 4. Basic inspection methods
# =============================================================

print(f"Row count    : {df.count()}")
print(f"Column count : {len(df.columns)}")
print(f"Columns      : {df.columns}")
print(f"dtypes       : {df.dtypes}")


# =============================================================
# 5. createDataFrame with explicit column types (StructType)
# =============================================================
# When you want Spark to use specific types instead of inferring,
# pass a StructType schema as the second argument.

from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType

schema = StructType([
    StructField("name",       StringType(),  True),
    StructField("department", StringType(),  True),
    StructField("salary",     DoubleType(),  True),   # force Double, not Long
    StructField("age",        IntegerType(), True),
])

df_typed = spark.createDataFrame(data, schema)

print("\n--- DataFrame with explicit schema (salary as Double) ---")
df_typed.show()
df_typed.printSchema()


# =============================================================
# 6. Stop the SparkSession
# =============================================================
# Always stop Spark at the end of your script.
# Releases resources and shuts down the Spark UI on port 4040.

spark.stop()
print("\nSparkSession stopped. Done.")
