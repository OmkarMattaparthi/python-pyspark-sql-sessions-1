# Day 1 - Practice Problems

**Topics covered:** SparkSession, createDataFrame, printSchema, basic inspection, StructType schema

---

## Problem 1 — Create a SparkSession and inspect it

Create a SparkSession with:
- App name: `"MyFirstApp"`
- 2 local cores (`local[2]`)
- `spark.sql.shuffle.partitions` set to `2`

After creating it, print:
- The Spark version
- The app name
- The master URL

---

## Problem 2 — Build a DataFrame from scratch

Create a DataFrame for the following student data:

| student_id | name    | course    | marks | passed |
|------------|---------|-----------|-------|--------|
| 1          | Ravi    | Python    | 85    | True   |
| 2          | Priya   | SQL       | 72    | True   |
| 3          | Arjun   | Python    | 45    | False  |
| 4          | Sneha   | Spark     | 91    | True   |
| 5          | Kiran   | SQL       | 38    | False  |

Use `spark.createDataFrame()` with a plain list of column names.

Then:
1. Call `show()` to display the data
2. Call `printSchema()` — note what types Spark infers for `marks` and `passed`

---

## Problem 3 — Inspect a DataFrame

Using the DataFrame from Problem 2:

1. Print the total row count
2. Print all column names as a list
3. Print the number of columns
4. Print `dtypes` — what does it show?

---

## Problem 4 — Define an explicit schema

Re-create the student DataFrame from Problem 2, but this time:
- Use a `StructType` schema
- `student_id` as `IntegerType`
- `name` and `course` as `StringType`
- `marks` as `DoubleType` (not Long)
- `passed` as `BooleanType`

Call `printSchema()` and compare with the inferred schema from Problem 2.

---

## Problem 5 — createDataFrame from a list of dicts

PySpark can also accept a list of dictionaries instead of tuples.

Create the same student DataFrame using:
```python
data = [
    {"student_id": 1, "name": "Ravi",  "course": "Python", "marks": 85.0, "passed": True},
    ...
]
df = spark.createDataFrame(data)
```

Call `show()` and `printSchema()`. Notice how column order may differ — why?

---

## Problem 6 — Explore SparkContext

From your SparkSession, access `spark.sparkContext` and print:
- `defaultParallelism` — how many cores are available?
- `appName`
- `master`

---

## Bonus — What happens without `spark.stop()`?

Modify the script so `spark.stop()` is at the top (before any operations) and observe the error. Then put it back at the end.
