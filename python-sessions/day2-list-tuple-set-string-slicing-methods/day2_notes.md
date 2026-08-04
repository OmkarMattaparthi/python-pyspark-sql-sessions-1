# Day 2 Notes — List, Tuple, Set, String: Slicing & Methods

## Topics Covered
1. Difference Between List, Tuple, Set, String
2. List — Slicing & Methods
3. Tuple — Slicing & Methods
4. Set — Methods (no slicing)
5. String — Slicing & Methods

---

## 1. Difference Between List, Tuple, Set, String

| Feature | List | Tuple | Set | String |
|---------|------|-------|-----|--------|
| Syntax | `[1, 2, 3]` | `(1, 2, 3)` | `{1, 2, 3}` | `"hello"` |
| Ordered | Yes | Yes | No | Yes |
| Mutable | Yes | No | Yes (add/remove) | No |
| Duplicates allowed | Yes | Yes | No | Yes |
| Indexing / Slicing | Yes | Yes | No | Yes |
| Use case | General data collection | Fixed/config data | Unique values, dedup | Text data |

### When to use what (Data Engineering context)

- **List** — column name lists, rows of data, pipeline step sequences
- **Tuple** — DB connection config `("host", 5432, "db")`, function returning multiple values, fixed schema
- **Set** — deduplication, finding unique departments/countries, checking column overlap between two schemas
- **String** — file paths, SQL queries, column names, log messages

---

## 2. List

### Slicing

Syntax: `list[start:stop:step]`
- `start` — index to begin (inclusive), default `0`
- `stop` — index to end (exclusive), default end of list
- `step` — how many to skip, default `1`

```python
nums = [10, 20, 30, 40, 50, 60, 70, 80]

nums[0:3]       # [10, 20, 30]         first 3
nums[2:6]       # [30, 40, 50, 60]     middle slice
nums[-3:]       # [60, 70, 80]         last 3
nums[::-1]      # [80, 70, 60, 50, 40, 30, 20, 10]  reversed
nums[::2]       # [10, 30, 50, 70]     every other element
nums[1::2]      # [20, 40, 60, 80]     every other starting from index 1
nums[:4]        # [10, 20, 30, 40]     first 4 (stop only)
nums[4:]        # [50, 60, 70, 80]     from index 4 to end
```

### Important List Methods

```python
fruits = ["banana", "apple", "cherry", "mango", "apple"]

# Add
fruits.append("grape")          # add to end → [..., "grape"]
fruits.insert(1, "kiwi")        # insert at index 1

# Remove
fruits.remove("apple")          # removes FIRST occurrence of "apple"
fruits.pop()                    # removes and returns last element
fruits.pop(0)                   # removes and returns element at index 0
del fruits[2]                   # delete at index 2

# Search
fruits.index("cherry")          # returns index of first match
fruits.count("apple")           # count occurrences → 2

# Sort & Order
fruits.sort()                   # sort ascending in place
fruits.sort(reverse=True)       # sort descending in place
fruits.reverse()                # reverse in place (not sort, just flip)
sorted(fruits)                  # returns NEW sorted list, original unchanged

# Info
len(fruits)                     # number of elements

# Copy & Clear
fruits.copy()                   # shallow copy of the list
fruits.clear()                  # empty the list → []

# Combine
a = [1, 2, 3]
b = [4, 5, 6]
a.extend(b)                     # adds all elements of b into a → [1,2,3,4,5,6]
a + b                           # creates new combined list
```

> **DE use case:** `extend()` to merge two column lists; `sort()` to canonicalize schema order before comparison; `copy()` to avoid mutating the original pipeline config.

---

## 3. Tuple

Tuples are **immutable** — once created, they cannot be changed. They are faster than lists and signal "this data should not change."

### Slicing

Same syntax as list — supports all slicing because tuples are ordered.

```python
coords = (10, 20, 30, 40, 50)

coords[1:4]     # (20, 30, 40)
coords[::-1]    # (50, 40, 30, 20, 10)   reversed
coords[::2]     # (10, 30, 50)
coords[-2:]     # (40, 50)               last 2
```

### Important Tuple Methods

Tuples have only **2 methods** (because they are immutable):

```python
t = (1, 2, 3, 2, 4, 2)

t.count(2)      # 3 — number of times 2 appears
t.index(3)      # 2 — index of first occurrence of 3
```

### Tuple Packing & Unpacking

```python
# packing
db_config = ("localhost", 5432, "warehouse_db")

# unpacking
host, port, db = db_config
print(host)     # "localhost"
print(port)     # 5432

# swap variables (uses tuple unpacking under the hood)
a, b = 10, 20
a, b = b, a
print(a, b)     # 20 10
```

### Tuple vs List — when to choose tuple
- Use **tuple** for data that must not change: DB credentials, column order definition, function returning multiple values
- Use **list** when you need to add, remove, or modify elements

> **DE use case:** `return (row_count, error_count)` from a validation function — unpacked cleanly by the caller.

---

## 4. Set

Sets are **unordered** and store only **unique** values. No indexing or slicing.

```python
s = {3, 1, 4, 1, 5, 9, 2, 6, 5}
print(s)    # {1, 2, 3, 4, 5, 6, 9} — duplicates removed, order not guaranteed
```

### Important Set Methods

```python
a = {1, 2, 3, 4, 5}
b = {4, 5, 6, 7, 8}

# Add / Remove
a.add(10)               # add single element
a.update([11, 12, 13])  # add multiple elements
a.remove(10)            # remove — raises KeyError if not found
a.discard(99)           # remove — NO error if not found (safer)
a.pop()                 # remove and return an arbitrary element

# Set Operations
a.union(b)              # {1,2,3,4,5,6,7,8}   — all elements from both
a | b                   # same as union

a.intersection(b)       # {4, 5}               — only elements in BOTH
a & b                   # same as intersection

a.difference(b)         # {1, 2, 3}            — in a but NOT in b
a - b                   # same as difference

a.symmetric_difference(b)  # {1,2,3,6,7,8}    — in either but NOT both
a ^ b                       # same

# Subset / Superset checks
{1, 2}.issubset({1, 2, 3})      # True  — all of {1,2} in {1,2,3}
{1, 2, 3}.issuperset({1, 2})    # True
{1, 2}.isdisjoint({3, 4})       # True  — no elements in common

# Info
len(a)
a.copy()
a.clear()
```

### Set Operations — Data Engineering Use Cases

```python
schema_v1 = {"id", "name", "salary", "dept"}
schema_v2 = {"id", "name", "salary", "email", "phone"}

# columns added in v2
schema_v2 - schema_v1           # {"email", "phone"}

# columns removed in v2
schema_v1 - schema_v2           # {"dept"}

# columns present in both
schema_v1 & schema_v2           # {"id", "name", "salary"}

# all columns across both versions
schema_v1 | schema_v2           # {"id", "name", "salary", "dept", "email", "phone"}
```

> **DE use case:** Schema drift detection — compare expected vs actual column sets to find added or missing columns.

---

## 5. String

Strings are **immutable sequences of characters**. They support indexing and slicing just like lists.

### Slicing

```python
text = "DataEngineering"

text[0]         # "D"              first character
text[-1]        # "g"              last character
text[0:4]       # "Data"
text[4:]        # "Engineering"
text[::-1]      # "gnireenignEataD"  reversed
text[::2]       # "DtEnierн"       every other character
text[0:4].lower()  # "data"        chain methods after slice
```

### Important String Methods

```python
s = "  Hello, Data Engineering World!  "

# Case
s.upper()           # "  HELLO, DATA ENGINEERING WORLD!  "
s.lower()           # "  hello, data engineering world!  "
s.title()           # "  Hello, Data Engineering World!  "
s.swapcase()        # flip upper↔lower for each char

# Strip whitespace / characters
s.strip()           # "Hello, Data Engineering World!"   both ends
s.lstrip()          # remove left whitespace only
s.rstrip()          # remove right whitespace only
s.strip("!")        # strip specific character

# Search & Check
s.find("Data")          # index of first occurrence, -1 if not found
s.index("Data")         # same but raises ValueError if not found
s.count("e")            # count occurrences
s.startswith("  Hello") # True
s.endswith("!  ")       # True
"123".isdigit()         # True — all characters are digits
"hello".isalpha()       # True — all alphabetic
"hello123".isalnum()    # True — alphanumeric
" ".isspace()           # True

# Replace & Split
s.replace("World", "Pipeline")     # new string with replacement
s.split(",")            # ["  Hello", " Data Engineering World!  "]
s.split()               # split on ANY whitespace, removes empty strings
"a-b-c".split("-")      # ["a", "b", "c"]
" ".join(["Data", "Engineering"])   # "Data Engineering"
",".join(["id", "name", "salary"])  # "id,name,salary"  — CSV header

# Padding & Alignment (useful for log formatting)
"42".zfill(5)           # "00042"   pad with zeros on left
"hi".ljust(10, "-")     # "hi--------"
"hi".rjust(10, "-")     # "--------hi"
"hi".center(10, "-")    # "----hi----"

# Check membership
"Eng" in "Data Engineering"     # True
```

### f-strings (modern string formatting)

```python
name    = "Alice"
salary  = 95000.5
dept    = "Engineering"

print(f"Employee: {name} | Dept: {dept} | Salary: {salary:.2f}")
# Employee: Alice | Dept: Engineering | Salary: 95000.50
```

> **DE use case:** Building dynamic SQL queries, formatting log messages, constructing file paths, parsing CSV headers.

---

## 6. Slicing Cheat Sheet

| Operation | List | Tuple | String | Set |
|-----------|------|-------|--------|-----|
| `[0]` first | Yes | Yes | Yes | No |
| `[-1]` last | Yes | Yes | Yes | No |
| `[1:4]` range | Yes | Yes | Yes | No |
| `[::-1]` reverse | Yes | Yes | Yes | No |
| `[::2]` step | Yes | Yes | Yes | No |

---

## 7. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| List slicing `[::2]` | Sample every Nth record from a dataset |
| `sort()` / `sorted()` | Canonicalize column order before schema comparison |
| `set` difference | Schema drift detection — find added/dropped columns |
| `set` intersection | Find common columns between two tables |
| `str.split()` / `join()` | Parse CSV headers, build SQL column lists |
| `str.strip()` | Clean whitespace from raw data values |
| `str.replace()` | Sanitize column names (spaces → underscores) |
| Tuple unpacking | Return multiple values from a function cleanly |
| `tuple` for config | Immutable DB credentials, fixed column order |
