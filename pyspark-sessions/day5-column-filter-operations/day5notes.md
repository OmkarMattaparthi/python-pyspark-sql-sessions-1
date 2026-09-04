# Day 5 - Column Operations and Filtering

---

## Table of Contents
1. [Column Selection — 6 Ways](#1-column-selection--6-ways)
2. [Creating New Columns — withColumn](#2-creating-new-columns--withcolumn)
3. [Type Casting](#3-type-casting)
4. [Filtering](#4-filtering)
5. [Quick Reference](#5-quick-reference)

---

## 1. Column Selection — 6 Ways

### 1A — String names (simplest)
```python
df.select("order_id", "customer_name", "status")
```
Use when: just picking columns, no transformation needed.

### 1B — col() objects
```python
from pyspark.sql.functions import col
df.select(col("order_id"), col("customer_name"), col("status"))
```
Use when: you need expressions, arithmetic, or aliases on the same column.

### 1C — col() with expression + alias
```python
df.select(
    col("order_id"),
    col("quantity"),
    col("unit_price"),
    (col("quantity") * col("unit_price")).alias("total_amount")
)
```

### 1D — List variable
```python
cols = ["order_id", "city", "category"]
df.select(cols)
```
Use when: column list comes from a config, loop, or user input.

### 1E — selectExpr (SQL strings)
```python
df.selectExpr(
    "order_id",
    "quantity * unit_price as total_amount",
    "upper(city) as city_upper"
)
```
Write SQL expressions directly as strings. No import needed for functions.

### 1F — Select all, then drop
```python
df.drop("is_returned", "order_date")
```
Use when: you want all columns except a few. Cleaner than listing 8 out of 10.

---

## 2. Creating New Columns — withColumn

`withColumn(name, expression)`
- If `name` is **new** → adds a new column
- If `name` **exists** → replaces that column

```python
from pyspark.sql.functions import (
    lit, concat_ws, year, month, dayofmonth,
    when, round
)
```

### Arithmetic
```python
df.withColumn("total_amount", col("quantity") * col("unit_price"))
```

### String concatenation
```python
df.withColumn("label", concat_ws(" | ", col("product"), col("city")))
```

### Constant value
```python
df.withColumn("currency", lit("INR"))
df.withColumn("tax_rate", lit(0.18))
```

### Date extraction
```python
df.withColumn("order_year",  year(col("order_date")))
df.withColumn("order_month", month(col("order_date")))
df.withColumn("order_day",   dayofmonth(col("order_date")))
```

### Conditional — when / otherwise
```python
df.withColumn(
    "order_tier",
    when(col("total_amount") >= 50000, "High Value")
    .when(col("total_amount") >= 10000, "Mid Value")
    .otherwise("Low Value")
)
```
Equivalent to SQL `CASE WHEN`. Always end with `.otherwise()`.

### Chaining withColumn calls
```python
df.withColumn("total_amount", col("quantity") * col("unit_price")) \
  .withColumn("tax",          round(col("total_amount") * 0.18, 2)) \
  .withColumn("net_payable",  round(col("total_amount") + col("tax"), 2))
```
Each step can reference columns added in the previous step.

---

## 3. Type Casting

### How to cast
```python
col("unit_price").cast("int")       # string type name
col("unit_price").cast("double")
col("unit_price").cast("string")
col("is_returned").cast("int")      # True -> 1, False -> 0
```

### Common type name strings

| String | Equivalent class |
|---|---|
| `"int"` / `"integer"` | `IntegerType()` |
| `"long"` | `LongType()` |
| `"double"` | `DoubleType()` |
| `"float"` | `FloatType()` |
| `"string"` | `StringType()` |
| `"boolean"` | `BooleanType()` |
| `"date"` | `DateType()` |
| `"timestamp"` | `TimestampType()` |

### Key rules

| Rule | Detail |
|---|---|
| Double → Int | Decimal is **truncated**, not rounded (`75000.9 → 75000`) |
| Boolean → Int | `true → 1`, `false → 0` |
| Bad cast | Returns **NULL**, does not throw an error |
| String → Int | Returns NULL if string is not a valid number |

### Check types
```python
df.printSchema()      # tree view
df.dtypes             # list of (name, type_string) tuples
```

---

## 4. Filtering

`filter()` and `where()` are **identical** — use whichever reads clearer.

### Operators

| Operator | Symbol | Rule |
|---|---|---|
| AND | `&` | Both conditions must be true |
| OR | `\|` | At least one condition must be true |
| NOT | `~` | Inverts the condition |

**Important:** Always wrap each condition in parentheses when combining.  
Use `&` `|` `~` — **NOT** Python's `and` `or` `not`.

### Single condition
```python
df.filter(col("status") == "delivered")
df.filter(col("unit_price") > 10000)
df.filter(col("is_returned") == True)
```

### AND — both must be true
```python
df.filter(
    (col("category") == "Electronics") & (col("status") == "delivered")
)
```

### OR — either is enough
```python
df.filter(
    (col("status") == "cancelled") | (col("is_returned") == True)
)
```

### NOT — invert a condition
```python
df.filter(~(col("status") == "cancelled"))
```

### Combining AND + OR
```python
df.filter(
    (col("status") == "delivered") &
    ((col("category") == "Electronics") | (col("category") == "Furniture"))
)
```

### isin — match any value from a list
```python
df.filter(col("city").isin("Mumbai", "Delhi", "Pune"))
df.filter(~col("category").isin("Electronics", "Grocery"))  # NOT isin
```
Cleaner than chaining many OR conditions.

### between — inclusive range
```python
df.filter(col("unit_price").between(1000, 10000))  # includes 1000 and 10000
```

### like — string pattern match
```python
df.filter(col("customer_name").like("R%"))   # starts with R
df.filter(col("product").like("%one%"))       # contains "one" anywhere
df.filter(col("city").like("_umbai"))         # _ = exactly one character
```

### isNull / isNotNull
```python
df.filter(col("discount").isNull())
df.filter(col("discount").isNotNull())
```

---

## 5. Quick Reference

### Column selection cheatsheet

| Goal | Method |
|---|---|
| Pick columns | `df.select("a", "b")` |
| Pick + expression | `df.select(col("a"), (col("b") * 2).alias("c"))` |
| SQL expression | `df.selectExpr("a", "b * 2 as c")` |
| From list | `df.select(["a", "b", "c"])` |
| Drop columns | `df.drop("x", "y")` |

### New column cheatsheet

| Goal | Code |
|---|---|
| Math | `withColumn("c", col("a") * col("b"))` |
| String join | `withColumn("c", concat_ws("-", col("a"), col("b")))` |
| Constant | `withColumn("c", lit("value"))` |
| Date part | `withColumn("yr", year(col("date_col")))` |
| Conditional | `withColumn("c", when(cond, v1).otherwise(v2))` |
| Type change | `withColumn("c", col("a").cast("int"))` |

### Filter cheatsheet

| Goal | Code |
|---|---|
| Equal | `col("x") == "val"` |
| Not equal | `col("x") != "val"` |
| Greater than | `col("x") > 100` |
| AND | `(cond1) & (cond2)` |
| OR | `(cond1) \| (cond2)` |
| NOT | `~(cond)` |
| In list | `col("x").isin("a", "b")` |
| Not in list | `~col("x").isin("a", "b")` |
| Range | `col("x").between(10, 100)` |
| Starts with | `col("x").like("R%")` |
| Contains | `col("x").like("%word%")` |
| Is NULL | `col("x").isNull()` |
| Is not NULL | `col("x").isNotNull()` |
