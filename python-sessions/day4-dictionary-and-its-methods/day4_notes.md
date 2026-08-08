# Day 4 Notes — Dictionary and its Methods

## Topics Covered
1. What is a Dictionary
2. Creating and Accessing a Dictionary
3. Nested Dictionaries
4. Add, Update, Delete Keys
5. Dictionary Methods
6. Iterating a Dictionary

---

## 1. What is a Dictionary

- Stores data as **key-value pairs**
- **Mutable** — you can add, update, or delete keys after creation
- **No index** — you access values using keys, not positions
- **Duplicate keys not allowed** — if the same key is added twice, the second value overwrites the first
- **Duplicate values are allowed** — two different keys can hold the same value
- Keys must be **immutable** types — string, int, tuple (not list)

```python
# Syntax
my_dict = {
    "key1": "value1",
    "key2": 42,
    "key3": [1, 2, 3]
}
```

---

## 2. Creating and Accessing a Dictionary

```python
students = {
    "name":     "Rahul",
    "course":   "DE",
    "duration": "4 Months",
    "age":      23,
    "marks":    [93, 93, 34, 93, 33.33]
}

# Direct access — raises KeyError if key doesn't exist
print(students["name"])         # "Rahul"
print(students["age"])          # 23

# .get() — returns None if key missing (no error)
print(students.get("school"))               # None
print(students.get("school", "No School"))  # "No School"  ← default value
print(students.get("age", "No Age"))        # 23  ← key exists, default ignored
```

> **DE rule:** Always use `.get()` when reading keys from API responses or config dicts — you don't know if the key will always be present. Direct `[]` access crashes if the key is missing.

---

## 3. Nested Dictionaries (Dict inside Dict / List inside Dict)

Real-world API responses are always nested. Practice reading them.

```python
students = {
    "name": "Rahul",
    "marks": [93, 93, 34, 93, 33.33],
    "details": [
        {"id": 1, "address1": "ABC"},
        {"id": 2, "address2": "DEF"}
    ]
}

# Access nested list
print(students["marks"])            # [93, 93, 34, 93, 33.33]
print(students["marks"][0])         # 93  ← first mark

# Access nested list of dicts
print(students["details"])          # full list
print(students["details"][0])       # {"id": 1, "address1": "ABC"}
print(students["details"][0]["id"]) # 1

# Get keys of a nested dict
print(students.get("details")[0].keys())   # dict_keys(["id", "address1"])
```

---

## 4. Add, Update, Delete Keys

```python
students = {"name": "Rahul", "age": 23}

# Add a new key
students["school"] = ["ABC School", "DEF School"]
print(students)

# Update an existing key's value
students["age"] = 55
print(students["age"])    # 55

# Delete a key — raises KeyError if not found
del students["age"]

# .pop(key) — removes and returns the value
removed = students.pop("name")
print(removed)            # "Rahul"

# .popitem() — removes and returns the LAST inserted key-value as a tuple
last = students.popitem()
print(last)               # ("school", ["ABC School", "DEF School"])
```

---

## 5. Dictionary Methods

```python
d = {"name": "Alice", "age": 30, "dept": "Engineering"}

# Keys, values, items
d.keys()        # dict_keys(["name", "age", "dept"])
d.values()      # dict_values(["Alice", 30, "Engineering"])
d.items()       # dict_items([("name", "Alice"), ("age", 30), ("dept", "Engineering")])

# get with default
d.get("salary", 0)     # 0 — key missing, returns default

# update — merge another dict into this one (overwrites matching keys)
d.update({"age": 31, "city": "Mumbai"})
print(d)   # {"name": "Alice", "age": 31, "dept": "Engineering", "city": "Mumbai"}

# copy — shallow copy
d2 = d.copy()

# clear — empties the dict
d.clear()
print(d)   # {}

# check if key exists
"name" in d       # True
"salary" in d     # False
```

### Method Summary Table

| Method | What it does |
|--------|-------------|
| `.get(key)` | Returns value or `None` — safe access |
| `.get(key, default)` | Returns value or default — safe access with fallback |
| `.keys()` | All keys |
| `.values()` | All values |
| `.items()` | All key-value pairs as tuples |
| `.update(dict2)` | Merge `dict2` into this dict |
| `.pop(key)` | Remove key and return its value |
| `.popitem()` | Remove and return last inserted key-value pair |
| `.copy()` | Shallow copy of the dict |
| `.clear()` | Remove all keys |

---

## 6. Iterating a Dictionary

```python
config = {"host": "localhost", "port": 5432, "db": "warehouse", "user": "admin"}

# Iterate keys only (default)
for key in config:
    print(key)
# host, port, db, user

# Iterate keys and access values
for key in config:
    print(key, config[key])      # or config.get(key)

# Iterate values only
for value in config.values():
    print(value)

# Iterate key-value pairs together — most common pattern
for key, value in config.items():
    print(f"{key} = {value}")
# host = localhost
# port = 5432
# db = warehouse
# user = admin
```

### Iterating a list of dicts (most common in DE — JSON records)

```python
employees = [
    {"id": 1, "name": "Alice", "dept": "Engineering"},
    {"id": 2, "name": "Bob",   "dept": "Sales"},
    {"id": 3, "name": "Carol", "dept": "Data"},
]

for emp in employees:
    print(emp["id"], emp["name"], emp["dept"])

# Filter while iterating
eng_team = [e for e in employees if e["dept"] == "Engineering"]
```

---

## 7. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| Dict key-value pairs | JSON API responses, config files, row-as-dict pattern |
| `.get(key, default)` | Safe field extraction from API responses — never crash on missing key |
| Nested dict access | Parse nested JSON: `row["address"]["city"]` |
| `.items()` iteration | Loop through config key-value pairs, build SQL column mappings |
| List of dicts | Every row returned by a REST API is a dict; a page = list of dicts |
| `.update()` | Merge two config dicts, add metadata fields to a record |
| `"key" in dict` | Check if a field exists before accessing it |
