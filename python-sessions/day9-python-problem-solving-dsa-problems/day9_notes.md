# Day 9 Notes — Python Problem Solving & DSA Problems

## Topics Covered
1. Short Circuit Evaluation
2. List Slicing Tricks
3. Flatten Nested Lists (Recursion)
4. Recursion Basics
5. Data Cleaning Pattern
6. Deduplication
7. break and continue in loops

---

## 1. Short Circuit Evaluation

Python stops evaluating a boolean expression as soon as the result is determined.

```python
# OR — stops at first True
a = 9
if a or some_undefined_variable:    # a=9 is truthy → stops here, never checks variable
    print("inside if")              # prints — no NameError

# AND — stops at first False
b = 0
if b and some_undefined_variable:   # b=0 is falsy → stops here
    print("won't run")
```

### Truthy and Falsy values

| Falsy | Truthy |
|-------|--------|
| `0`, `0.0` | Any non-zero number |
| `""` (empty string) | Non-empty string |
| `[]`, `{}`, `()` | Non-empty collection |
| `None` | Any object |
| `False` | `True` |

### Practical use — safe default with `or`

```python
name = ""
display = name or "Anonymous"   # name is falsy → uses "Anonymous"
print(display)                  # "Anonymous"

config = None
port = config or 5432           # config is None (falsy) → uses 5432
```

> **DE use case:** Safe fallback for missing config values, optional API fields, nullable DB columns.

---

## 2. List Slicing Tricks

```python
list1 = [3, 5, 2, 0, 3, 0, 8, 5]
#  idx:  0  1  2  3  4  5  6  7

# Reverse the list
print(list1[::-1])          # [5, 8, 0, 3, 0, 2, 5, 3]

# Every 2nd element
print(list1[::2])           # [3, 2, 3, 8]

# From index -2, going backwards with step 2
print(list1[-2::-2])        # [8, 3, 0, 5]
# starts at index 6 (value=8), then 4 (value=3), then 2 (value=0), then 0 (value=5... wait)
# index 6=8, step=-2 → index 4=3, index 2=0... wait: [8, 3, 0, 5]? no
# list1[-2] = list1[6] = 8 → step -2 → index 4=3, index 2=2... 
# Actual: [8, 3, 2, 5] — trace carefully

# Last N elements
print(list1[-3:])           # [0, 8, 5]

# First N elements
print(list1[:3])            # [3, 5, 2]

# Remove first and last
print(list1[1:-1])          # [5, 2, 0, 3, 0, 8]
```

> Slicing never raises IndexError — out-of-range stops gracefully at the list boundary.

---

## 3. Flatten Nested Lists — Recursion

Flattening means converting a nested list of any depth into a single flat list.

```python
list2 = [[1, 2], [3, 4], [5, 6, 7, [1, 2, 3]]]
# expected: [1, 2, 3, 4, 5, 6, 7, 1, 2, 3]

def flatten(data):
    result = []
    for item in data:
        try:
            result.extend(flatten(item))   # try to recurse — works if item is iterable
        except TypeError:
            result.append(item)            # item is a plain value (int) — just append
    return result

print(flatten(list2))    # [1, 2, 3, 4, 5, 6, 7, 1, 2, 3]
```

**How it works:**
- For each item: try to call `flatten(item)` recursively
- If `item` is a list → recursion works → extends result with flattened sub-list
- If `item` is an int → `flatten(5)` tries `for x in 5` → `TypeError` → just append

> **DE use case:** Flattening nested JSON arrays before inserting into a DB table.

---

## 4. Recursion Basics

A recursive function calls **itself** with a smaller input until it reaches a **base case** that stops the recursion.

```python
def hell(n):
    if n == 0:          # base case — stops recursion
        return
    print(f"Hello {n}")
    hell(n - 1)         # recursive call with smaller n

hell(3)
# Hello 3
# Hello 2
# Hello 1
```

**Call stack trace:**
```
hell(3) → prints "Hello 3" → calls hell(2)
  hell(2) → prints "Hello 2" → calls hell(1)
    hell(1) → prints "Hello 1" → calls hell(0)
      hell(0) → base case → returns
```

> **Rule:** Every recursive function must have a base case. Without it → infinite recursion → `RecursionError`.

---

## 5. Data Cleaning Pattern

Clean a list of records by removing invalid rows and normalizing field values.

```python
users = [
    {"id": 1, "name": "  amit sharma ", "age": 25},
    {"id": 2, "name": "RAHUL KUMAR",    "age": 30},
    {"id": 3, "name": "",               "age": 22},
    {"id": 4, "name": " priya ",        "age": None},
    {"id": 5, "name": "  raj  ",        "age": 28}
]

clean_users = []
for user in users:
    name = user["name"].strip()
    age  = user["age"]

    if name == "":      # skip empty name
        continue
    if age is None:     # skip missing age
        continue

    user["name"] = name.title()     # "amit sharma" → "Amit Sharma"
    clean_users.append(user)

print(clean_users)
# [{"id":1,"name":"Amit Sharma","age":25}, {"id":2,"name":"Rahul Kumar","age":30}, {"id":5,"name":"Raj","age":28}]
```

**Rules applied:**
1. Strip spaces from name
2. Skip if name is empty after strip
3. Skip if age is `None`
4. Convert name to title case

> **DE use case:** This exact pattern runs on every row of a raw API response or CSV file before inserting into a DB.

---

## 6. Deduplication

Remove duplicate records from a list of dicts based on a key field.

```python
customers = [
    {"id": 101, "name": "Amit",  "email": "amit@gmail.com"},
    {"id": 102, "name": "Rahul", "email": "rahul@gmail.com"},
    {"id": 101, "name": "Amit",  "email": "amit@gmail.com"},   # duplicate
    {"id": 103, "name": "Priya", "email": "priya@gmail.com"},
    {"id": 102, "name": "Rahul", "email": "rahul@gmail.com"},  # duplicate
]

# Method 1 — using a seen set
seen = set()
unique = []
for c in customers:
    if c["id"] not in seen:
        seen.add(c["id"])
        unique.append(c)

print(unique)
# [{"id":101,...}, {"id":102,...}, {"id":103,...}]

# Method 2 — dict comprehension (keeps last occurrence)
unique2 = list({c["id"]: c for c in customers}.values())
```

> **DE use case:** Dedup records before upsert to DB, remove duplicate API responses from paginated fetches.

---

## 7. break and continue

```python
# break — exit loop immediately when condition met
list1 = [1, 2, 3, 4, 5]
for num in list1:
    if num > 3:
        break
    print(num)
# prints: 1, 2, 3

# continue — skip current iteration, move to next
for num in list1:
    if num == 3:
        continue
    print(num)
# prints: 1, 2, 4, 5
```

---

## 8. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| Short circuit `or` | Safe fallback: `value = api_field or default` |
| Short circuit `and` | Guard: `if conn and conn.open: query()` |
| Slicing `[1:-1]` | Strip header/footer rows from raw files |
| `[::-1]` | Reverse a list of pipeline steps for rollback |
| `flatten()` recursion | Normalize nested JSON arrays to flat rows |
| Recursion | Tree traversal, nested config parsing |
| Data cleaning loop | Validate + normalize every raw record before DB insert |
| Deduplication | Remove duplicate records before upsert |
| `break` | Stop scan once match found — early exit optimization |
| `continue` | Skip invalid/null rows, process the rest |
