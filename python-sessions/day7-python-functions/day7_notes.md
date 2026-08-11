# Day 7 Notes — Python Functions

## Topics Covered
1. What is a Function
2. Defining and Calling Functions
3. Function Arguments — positional, default, keyword, *args, **kwargs
4. Return Values
5. Lambda Functions
6. Copy vs Deep Copy

---

## 1. What is a Function

A function is a **reusable block of code** with a name. Instead of writing the same logic multiple times, you define it once and call it wherever needed.

```python
# Without function — repeated code
name1 = "Alice"
print(f"Hello {name1}")

name2 = "Bob"
print(f"Hello {name2}")

# With function — one definition, reuse anywhere
def greet(name):
    print(f"Hello {name}")

greet("Alice")
greet("Bob")
```

**Benefits:**
- Avoid repetition (DRY — Don't Repeat Yourself)
- Easier to test and debug
- Makes code readable and organized

---

## 2. Defining and Calling Functions

```python
# Syntax
def function_name(parameters):
    # body
    return value       # optional

# Define
def say_hello():
    print("Hello World")

# Call
say_hello()            # Hello World
```

---

## 3. Function Arguments

### Positional arguments — order matters

```python
def sum_custom(a, b):
    return a + b

print(sum_custom(3, 2))    # 5
print(sum_custom(10, 5))   # 15
```

### Default arguments — fallback if not passed

```python
def sum_default(a=3, b=3):
    return a + b

print(sum_default())        # 6  — both defaults used
print(sum_default(9))       # 12 — a=9, b uses default 3
print(sum_default(9, 1))    # 10 — both overridden
```

### Keyword arguments — pass by name, order doesn't matter

```python
def describe(a, b):
    print(f"a={a}, b={b}")

describe(b=6, a=7)    # a=7, b=6  — order swapped but named
```

### *args — accept any number of positional arguments

```python
def sum_all(*numbers):    # numbers becomes a tuple
    print(numbers)        # (1, 2, 3, 5, 5)
    return sum(numbers)

print(sum_all(1, 2, 3, 5, 5))   # 16
```

### **kwargs — accept any number of keyword arguments

```python
def show_info(**info):    # info becomes a dict
    print(info)

show_info(name="Alice", dept="Data", salary=90000)
# {"name": "Alice", "dept": "Data", "salary": 90000}
```

### Order of parameters

```python
# Correct order: positional → *args → keyword-only → **kwargs
def pipeline(name, *tables, env="prod", **options):
    print(name, tables, env, options)

pipeline("etl", "orders", "users", env="dev", retry=3)
```

---

## 4. Return Values

```python
def do_square(n):
    return n * n

result = do_square(8)
print(result)          # 64

# Return multiple values (returns a tuple)
def min_max(numbers):
    return min(numbers), max(numbers)

low, high = min_max([3, 1, 9, 5])
print(low, high)       # 1 9
```

> A function without a `return` statement returns `None`.

---

## 5. Lambda Functions

A **lambda** is a small anonymous function written in one line. Used when you need a short function without defining it with `def`.

```python
# Syntax: lambda arguments: expression

# Regular function
def square(x):
    return x * x

# Same as lambda
square = lambda x: x * x

print(square(7))    # 49
```

### Lambda with multiple arguments

```python
add = lambda a, b: a + b
print(add(3, 5))    # 8
```

### Lambda inside `sorted()`

```python
employees = [
    {"name": "Bob",   "salary": 72000},
    {"name": "Alice", "salary": 95000},
    {"name": "Carol", "salary": 88000},
]

# Sort by salary ascending
sorted_emp = sorted(employees, key=lambda e: e["salary"])

# Sort by salary descending
sorted_emp = sorted(employees, key=lambda e: e["salary"], reverse=True)
```

> **DE use case:** Lambda functions are heavily used with `map()`, `filter()`, `sorted()`, and `groupBy()` in PySpark.

---

## 6. Copy vs Deep Copy

When you assign a list to another variable, both point to the **same object** in memory — modifying one changes the other.

```python
from copy import copy, deepcopy

list1 = [1, 2, 3, 4, 5, [6, 7, 9]]

list2 = list1           # reference — same object
list3 = copy(list1)     # shallow copy — new outer list, shared inner list
list4 = deepcopy(list1) # deep copy — completely independent

print(id(list1), id(list1[5]))   # same address for inner list
print(id(list2), id(list2[5]))   # same as list1 — they ARE the same object
print(id(list3), id(list3[5]))   # new outer id, but inner list id = list1's inner
print(id(list4), id(list4[5]))   # completely new ids — fully independent
```

### The difference matters when you modify nested data

```python
list1[5][0] = 60

print(list2)   # [1, 2, 3, 4, 5, [60, 7, 9]]  ← changed (same object as list1)
print(list3)   # [1, 2, 3, 4, 5, [60, 7, 9]]  ← changed (shallow — shared inner list)
print(list4)   # [1, 2, 3, 4, 5, [6, 7, 9]]   ← unchanged (deep copy)
```

### Summary table

| Assignment | Outer list | Inner list | Independent? |
|-----------|-----------|-----------|-------------|
| `list2 = list1` | Same | Same | No |
| `list3 = copy(list1)` | New | Same (shared) | Partially |
| `list4 = deepcopy(list1)` | New | New | Yes — fully |

> **DE use case:** When passing a config dict or schema to multiple pipeline steps, use `deepcopy` so one step can't accidentally modify another step's config.

---

## 7. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| `def` functions | Wrap ingestion, transformation, validation logic — reuse across pipelines |
| Default args | `def fetch(endpoint, page=1, page_size=500)` — sensible defaults for API calls |
| `*args` | Accept variable number of column names or table names |
| `**kwargs` | Pass arbitrary config options through to connectors |
| `return` multiple values | Return `(row_count, error_count)` from a validation function |
| Lambda | Inline transforms in `map()`, `filter()`, `sorted()`, PySpark `.withColumn()` |
| `deepcopy` | Safely copy schema/config dicts before mutating in a pipeline step |
