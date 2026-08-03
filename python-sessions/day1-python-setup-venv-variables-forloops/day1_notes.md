# Day 1 Notes — Python Fundamentals for Data Engineering

## Topics Covered
1. Python Setup & Virtual Environments
2. Variables & Data Types
3. Operators (Arithmetic, Comparison, Logical, Membership, Identity)
4. Lists — Indexing, Slicing, Methods

---

## 1. Python Setup & Virtual Environments

### Why venv matters in Data Engineering
- Each project (PySpark, Airflow, dbt) needs different library versions.
- venv prevents version conflicts between projects.
- Reproducibility: `requirements.txt` lets teammates or CI/CD recreate the exact environment.

### Key commands recap
```python
import sys
print(sys.version)
```

---

## 2. Variables & Data Types

Python is dynamically typed — the type is inferred from the value assigned.

```python
number       = 44
float_value  = 433.33
string_value = "Python Session"
bool_value   = True        # True or False (case-sensitive)

print(number, float_value, string_value, bool_value)
# 44 433.33 Python Session True

print(type(number))        # <class 'int'>
print(type(float_value))   # <class 'float'>
print(type(string_value))  # <class 'str'>
```

### Taking user input
```python
name = input("Enter your name: ")   # always returns str
age  = int(input("Enter age: "))    # cast to int explicitly
```

### Data Engineering Relevance
- Reading CSV/JSON data always comes in as `str` — you must cast to `int`/`float`/`datetime`.
- `None` in Python maps to `NULL` in SQL and `null` in JSON.

---

## 3. Operators

### Arithmetic Operators

| Operator | Meaning | Example | Result |
|----------|---------|---------|--------|
| `+` | Addition | `5 + 3` | `8` |
| `-` | Subtraction | `5 - 3` | `2` |
| `*` | Multiplication | `5 * 3` | `15` |
| `/` | Division (float) | `11 / 5` | `2.2` |
| `//` | Floor Division | `11 // 5` | `2` |
| `%` | Modulus (remainder) | `11 % 5` | `1` |
| `**` | Exponent | `2 ** 3` | `8` |

```python
print(11 // 5)   # 2   — drops the decimal
print(11 % 5)    # 1   — remainder only
print(11 / 5)    # 2.2 — true division
```

> **DE use case:** `%` is used for even/odd checks, batch partitioning, modulo-based hashing in distributed systems.

---

### Comparison Operators

Return `True` or `False`. Used heavily in filtering data.

| Operator | Meaning |
|----------|---------|
| `==` | Equal to |
| `!=` | Not equal to |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

```python
print(5 == 5.0)    # True  — int and float compared by value
print(5 != 5)      # False
print(10 < 10)     # False
print(10 > 10)     # False
print(10 >= 10)    # True
print(10 <= 10)    # True
```

> **Note:** `5 == 5.0` is `True` because Python compares values, not types.

---

### Logical Operators

Combine multiple conditions. Used in `if` statements and filter expressions.

| Operator | Meaning |
|----------|---------|
| `and` | Both conditions must be True |
| `or` | At least one condition must be True |
| `not` | Inverts the condition |

```python
a = 7
if a > 5 and a % 5 == 0:
    print('Inside If statement')
else:
    print('else statement')
# Output: else statement
# a=7 is > 5 (True) but 7%5 = 2, not 0 (False) — AND needs both True
```

---

### Membership Operators

Check if a value exists in a sequence (list, string, tuple, etc.).

| Operator | Meaning |
|----------|---------|
| `in` | Value exists in the sequence |
| `not in` | Value does not exist in the sequence |

```python
if 10 not in [15, 12, 39]:
    print('not available')
else:
    print('available')
# Output: not available
```

> **DE use case:** Checking if a column name exists in a schema list, or if a key exists in a config dict.

---

### Identity Operators

Check if two variables point to the **same object in memory** (not just equal values).

| Operator | Meaning |
|----------|---------|
| `is` | Same object in memory |
| `is not` | Different objects in memory |

```python
a = 5
b = 5
print(a is b)       # True  — Python caches small integers
print(a is not b)   # False

# With lists — different objects even if values are equal
a = [1, 2, 3]
b = a               # b points to the SAME list object
print(id(a))        # same memory address
print(id(b))        # same memory address
print(a == b)       # True  — values are equal
print(a is b)       # True  — same object in memory
```

> **Key distinction:** `==` compares **values**, `is` compares **memory identity**.  
> Always use `==` for value comparisons. Use `is` only for `None` checks: `if x is None`.

---

## 4. Lists

A list is an **ordered, mutable** collection that can hold mixed types.

```python
students = ["Hariom", "Python", 89, 78.54, ['python', 'sql', 'pyspark']]
print(students)
# ['Hariom', 'Python', 89, 78.54, ['python', 'sql', 'pyspark']]
```

### Indexing

Indexing starts at `0`. Negative index counts from the end.

```python
print(students[0])    # "Hariom"     — first element
print(students[-1])   # ['python', 'sql', 'pyspark']  — last element
```

### Slicing

Syntax: `list[start:stop]` — includes `start`, excludes `stop`.

```python
print(students[0:2])  # ['Hariom', 'Python']
```

### Slicing with Step

Syntax: `list[start:stop:step]`

```python
numbers = [1, 2, 3, 4, 5, 6, 7]
print(numbers[0:7:2])   # [1, 3, 5, 7] — every 2nd element
```

### Nested List Access

```python
students = ["Hariom", "Python", 89, 78.54, ['python', 'sql', 'pyspark']]
print(students[4][1])   # 'sql' — index into the inner list
```

### Common List Methods

| Method | Description | Example |
|--------|-------------|---------|
| `len()` | Number of elements | `len(students)` → `5` |
| `append()` | Add item to end | `students.append("new")` |
| `remove()` | Remove first match | `students.remove(89)` |
| `pop()` | Remove by index | `students.pop(0)` |
| `sort()` | Sort in place | `numbers.sort()` |
| `reverse()` | Reverse in place | `numbers.reverse()` |
| `index()` | Find index of value | `numbers.index(3)` |
| `count()` | Count occurrences | `numbers.count(1)` |

```python
print(len(students))    # 5
```

> **DE use case:** Lists represent rows of data, column name lists, or file path batches before loading into a DataFrame.

---

## 5. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| Variables & Types | Schema definitions, casting raw source data |
| `//` and `%` | Batch partitioning, hash-based distribution |
| Comparison operators | Row-level filtering conditions |
| `and` / `or` | Multi-condition filters (like SQL `WHERE x AND y`) |
| `in` / `not in` | Column existence checks, allow/blocklist filtering |
| `is None` | NULL checks before transforms |
| Lists + slicing | Column subsets, windowed batch reads |
| Nested lists | Representing table rows before loading to DataFrames |
