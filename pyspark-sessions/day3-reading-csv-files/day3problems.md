# Day 3 - Practice Problems

**Topics:** Reading CSV, inferSchema vs defined schema, parse modes, multiple files

All sample files are inside `data/`.

---

## Problem 1 — Basic CSV read

1. Read `employees.csv` with `header=True` and `inferSchema=True`. Call `show()` and `printSchema()`.
2. Read the same file using the full `.format("csv").option(...).load(...)` style instead of shorthand.
3. What type does Spark infer for `salary`? What type does it infer for `join_date`?

---

## Problem 2 — option() and options()

Read `employees.csv` using `.option()` chaining with all of these set:
- `header = true`
- `inferSchema = true`
- `nullValue = N/A`
- `dateFormat = yyyy-MM-dd`
- `ignoreLeadingWhiteSpace = true`
- `ignoreTrailingWhiteSpace = true`

Then repeat using `.options()` with all options passed at once. Confirm both produce the same schema.

---

## Problem 3 — No header row

1. Read `employees_no_header.csv` with `header=False`. What are the auto-generated column names?
2. Rename all columns to: `emp_id`, `name`, `department`, `salary`, `age`, `join_date`, `is_active` using `.toDF()`.
3. Now read the same file again with a DDL schema string so Spark assigns the column names directly — no `.toDF()` needed.

---

## Problem 4 — Custom delimiter

1. Read `employees_pipe.csv` — it uses `|` as the separator. Show the result.
2. What would you set `sep` to for a tab-separated file? For a semicolon-separated file?

---

## Problem 5 — Multiline values

1. Read `employees_multiline.csv` without `multiLine=True`. What happens to Bob's row?
2. Read it again with `multiLine=True`, `quote='"'`, `escape='"'`. How many rows do you get now?

---

## Problem 6 — Dirty data and parse modes

Using `employees_dirty.csv`:

1. Read with `PERMISSIVE` mode and `nullValue="N/A"`. Which columns have NULLs and why?
2. Read with `DROPMALFORMED`. How many rows remain? Compare with PERMISSIVE.
3. Without running it, explain: when would you use `FAILFAST` in a production pipeline?

---

## Problem 7 — Defined schema with StructType

Define a `StructType` schema for employees:
- `emp_id`: IntegerType
- `name`: StringType
- `department`: StringType
- `salary`: DoubleType
- `age`: IntegerType
- `join_date`: DateType
- `is_active`: BooleanType

Read `employees.csv` using this schema with `dateFormat="yyyy-MM-dd"`.

1. Call `printSchema()` — how does `salary` differ from the inferred schema in Problem 1?
2. How does `join_date` differ?

---

## Problem 8 — DDL schema string

Write the same schema from Problem 7 as a single DDL string and read the file again.

1. Are the results identical to the StructType approach?
2. Read `employees_no_header.csv` using the DDL schema with `header=False`. Does the column order matter?

---

## Problem 9 — Multiple files

1. Read `employees.csv` and `employees_no_header.csv` together using a list of paths. How many total rows?
2. Add a `source_file` column using `input_file_name()`. Show `emp_id`, `name`, `source_file`.
3. What is the full file URI that appears in `source_file`? Is it a relative or absolute path?

---

## Problem 10 — Combining everything

Write a single read that:
- Reads `employees.csv`
- Uses a defined schema (StructType or DDL — your choice)
- Sets `dateFormat = "yyyy-MM-dd"`
- Sets `nullValue = "N/A"`
- Sets `mode = "PERMISSIVE"`

Then:
1. Show the data
2. Filter rows where `is_active = true`
3. Show the count of active vs inactive employees using `groupBy`

---

## Bonus — Schema mismatch

Define a StructType where `salary` is `StringType` (wrong on purpose).  
Read `employees.csv` using this schema and call `show()`.

1. What value does salary show?
2. Now cast it to `DoubleType` using `.withColumn("salary", col("salary").cast("double"))` and show again.
