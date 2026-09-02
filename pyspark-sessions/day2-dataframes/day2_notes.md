# Day 2 - DataFrame Operations in PySpark

---

## Table of Contents
1. [DataFrames are Immutable](#1-dataframes-are-immutable)
2. [select](#2-select)
3. [filter / where](#3-filter--where)
4. [withColumn](#4-withcolumn)
5. [groupBy + Aggregation](#5-groupby--aggregation)
6. [orderBy / sort](#6-orderby--sort)
7. [Lazy Evaluation and explain()](#7-lazy-evaluation-and-explain)
8. [toPandas](#8-topandas)
9. [Rename and Drop Columns](#9-rename-and-drop-columns)
10. [Key Functions Reference](#10-key-functions-reference)

---

## 1. DataFrames are Immutable

Every transformation on a DataFrame returns a **new** DataFrame. The original is never modified.

```python
df2 = df.filter(col("salary") > 60000)  # df is unchanged
```

This is by design — Spark tracks transformations as a DAG (Directed Acyclic Graph) and replays them if a partition is lost.

---

## 2. select

Pick specific columns, or build derived columns.

```python
# By name
df.select("name", "salary").show()

# Using col() for expressions
from pyspark.sql.functions import col
df.select(col("name"), (col("salary") * 1.1).alias("new_salary")).show()

# All columns + a new derived one
df.select("*", (col("salary") / 83).cast("int").alias("salary_usd")).show()
```

### col() vs string name

| Style | When to use |
|---|---|
| `"column_name"` | Simple picks, no expression |
| `col("column_name")` | Arithmetic, conditions, `.alias()` |

---

## 3. filter / where

`filter()` and `where()` are identical. Use whichever reads more clearly.

```python
df.filter(col("salary") > 65000)
df.where(col("department") == "Engineering")
```

### Combining conditions

```python
# AND
df.filter((col("dept") == "Engineering") & (col("salary") > 80000))

# OR
df.filter((col("dept") == "HR") | (col("age") < 27))

# isin
df.filter(col("department").isin("Engineering", "HR"))

# NULL checks
df.filter(col("bonus").isNull())
df.filter(col("bonus").isNotNull())
```

**Important:** Use `&` `|` `~` — NOT Python's `and` `or` `not`. Always wrap each condition in parentheses.

---

## 4. withColumn

Add or replace a column.

```python
# Add new column
df.withColumn("salary_usd", (col("salary") / 83).cast("int"))

# Replace existing column
df.withColumn("department", upper(col("department")))

# Constant column
from pyspark.sql.functions import lit
df.withColumn("country", lit("India"))

# Conditional column
from pyspark.sql.functions import when
df.withColumn(
    "level",
    when(col("salary") >= 80000, "Senior")
    .when(col("salary") >= 60000, "Mid")
    .otherwise("Junior")
)
```

### cast() — change a column's data type

```python
df.withColumn("salary", col("salary").cast("double"))
df.withColumn("age",    col("age").cast("string"))
```

---

## 5. groupBy + Aggregation

```python
from pyspark.sql.functions import count, avg, sum, min, max

# Single aggregation
df.groupBy("department").count()
df.groupBy("department").agg(avg("salary").alias("avg_salary"))

# Multiple aggregations
df.groupBy("department").agg(
    count("*").alias("headcount"),
    avg("salary").alias("avg_salary"),
    max("salary").alias("max_salary"),
    min("age").alias("youngest_age")
)
```

### Common aggregate functions

| Function | Import | What it does |
|---|---|---|
| `count("*")` | `count` | Count all rows |
| `avg("col")` | `avg` | Average |
| `sum("col")` | `sum` | Total sum |
| `min("col")` | `min` | Minimum value |
| `max("col")` | `max` | Maximum value |
| `round(expr, n)` | `round` | Round to n decimal places |

---

## 6. orderBy / sort

```python
# Single column descending
df.orderBy(col("salary").desc())

# Multiple columns
df.orderBy(col("department").asc(), col("salary").desc())

# String shorthand (ascending by default)
df.orderBy("department", "salary")
```

`sort()` and `orderBy()` are identical.

---

## 7. Lazy Evaluation and explain()

Transformations are **lazy** — they build a plan but run nothing:

```python
plan = df \
    .filter(col("age") > 28) \
    .withColumn("seniority", lit("Senior")) \
    .select("name", "department", "salary", "seniority")
# No data processed yet — just a plan
```

An **action** triggers execution:

| Action | What it does |
|---|---|
| `show()` | Print rows to console |
| `count()` | Count rows |
| `collect()` | Return all rows to driver as a list |
| `write` | Write data to storage |

```python
plan.explain()   # print the physical execution plan
plan.show()      # this is the action that runs everything
```

---

## 8. toPandas

Collects all data to the driver as a Pandas DataFrame.

```python
pandas_df = df.filter(col("department") == "Engineering").toPandas()
print(pandas_df)
```

**When to use:** Final display, plotting, exporting small results.  
**Never use on large DataFrames** — it pulls everything to one machine.

---

## 9. Rename and Drop Columns

```python
# Rename
df.withColumnRenamed("name", "employee_name")

# Rename via select + alias
df.select(col("name").alias("employee_name"), "salary")

# Drop
df.drop("age")
df.drop("age", "bonus")   # drop multiple at once
```

---

## 10. Key Functions Reference

```python
from pyspark.sql.functions import (
    col,            # column reference / expression
    lit,            # constant value
    upper, lower,   # string case
    when,           # conditional (like CASE WHEN)
    count, avg, sum, min, max,  # aggregations
    round,          # rounding
)
```

| Function | Example |
|---|---|
| `col("x")` | Reference column x |
| `lit(42)` | Add constant column |
| `upper(col("x"))` | Uppercase string |
| `when(cond, v).otherwise(v2)` | Conditional value |
| `col("x").alias("y")` | Rename in select |
| `col("x").cast("double")` | Change type |
| `col("x").isNull()` | NULL check |
| `col("x").isin("a","b")` | IN check |
