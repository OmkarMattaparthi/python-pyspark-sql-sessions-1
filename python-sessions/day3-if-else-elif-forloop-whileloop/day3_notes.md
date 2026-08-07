# Day 3 Notes — if / elif / else, for loop, while loop

## Topics Covered
1. if / elif / else — Conditional Logic
2. for loop — Iterating over sequences and ranges
3. while loop — Condition-based repetition
4. Loop control — break, continue, pass

---

## 1. if / elif / else

### Syntax

```python
if condition:
    # runs when condition is True
elif another_condition:
    # runs when first is False, this is True
else:
    # runs when all above are False
```

### Rules
- Only one `if` per block — required
- Any number of `elif` — optional
- Only one `else` — optional, must be last
- Python uses **indentation** (4 spaces) to define blocks — no curly braces

### Examples

```python
status_code = 404

if status_code == 200:
    print("OK")
elif status_code == 201:
    print("Created")
elif status_code == 403:
    print("Forbidden")
elif status_code == 404:
    print("Not Found")
else:
    print("Unknown status")
```

```python
number = 7

if number > 8:
    print("greater than 8")
elif number > 5:
    print("greater than 5")   # ← this prints
elif number > 2:
    print("greater than 2")
else:
    print("2 or less")
```

> **Important:** Python evaluates conditions top-to-bottom and stops at the FIRST match. Once a block runs, the rest are skipped.

### Comparison Operators

| Operator | Meaning |
|----------|---------|
| `==` | equal to |
| `!=` | not equal to |
| `>` | greater than |
| `<` | less than |
| `>=` | greater than or equal |
| `<=` | less than or equal |

### Logical Operators

```python
# and — both conditions must be True
if age > 18 and salary > 50000:
    print("eligible")

# or — at least one must be True
if dept == "Engineering" or dept == "Data":
    print("tech team")

# not — flips True/False
if not is_error:
    print("pipeline healthy")
```

### Membership check with in

```python
valid_formats = ["csv", "parquet", "json"]
file_ext = "csv"

if file_ext in valid_formats:
    print("valid format")
else:
    print("unsupported format")
```

> **DE use case:** Check HTTP response codes from an API, validate file formats before ingestion, route records by department or category.

---

## 2. for loop

Iterates over any **iterable** — list, tuple, string, range, set, dict.

### Syntax

```python
for variable in iterable:
    # body — runs once per item
```

### range()

```python
range(stop)           # 0 to stop-1
range(start, stop)    # start to stop-1
range(start, stop, step)  # with step

range(5)          # 0, 1, 2, 3, 4
range(1, 6)       # 1, 2, 3, 4, 5
range(0, 10, 2)   # 0, 2, 4, 6, 8
range(10, 0, -1)  # 10, 9, 8, ..., 1  (countdown)
```

### Looping over a list

```python
list1 = [5, 3, 9, 0, 11, 10]

for value in list1:
    if value > 5:
        print(value)   # prints 9, 11, 10
```

### Looping with index — enumerate()

```python
columns = ["id", "name", "salary"]

for index, col in enumerate(columns):
    print(index, col)
# 0 id
# 1 name
# 2 salary
```

### Looping over a string

```python
for char in "Data":
    print(char)   # D, a, t, a
```

### Looping over a dict

```python
config = {"host": "localhost", "port": 5432, "db": "warehouse"}

for key in config:
    print(key)                       # keys only

for key, value in config.items():
    print(f"{key} = {value}")        # key-value pairs
```

### Nested for loops

```python
table = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

for row in table:
    for cell in row:
        print(cell, end=" ")
    print()
```

> **DE use case:** Iterate over a list of file paths to load each one, loop over column names to build SQL, process each row of a dataset.

---

## 3. while loop

Runs as long as a condition is `True`. Use when you **don't know in advance** how many times to loop.

### Syntax

```python
while condition:
    # body
    # must eventually make condition False — else infinite loop
```

### Example

```python
number = 1
while number < 100:
    print(number)
    number += 1       # number = number + 1
```

### Common pattern — counter

```python
count = 0
while count < 5:
    print(f"attempt {count + 1}")
    count += 1
```

### Common pattern — retry loop

```python
retries = 0
max_retries = 3
success = False

while retries < max_retries and not success:
    print(f"Connecting... attempt {retries + 1}")
    # simulate connection logic
    retries += 1
```

> **Warning:** Always update the variable that controls the condition. Forgetting `number += 1` causes an **infinite loop**.

> **DE use case:** Poll an API until data is ready, retry a failed DB connection up to N times, paginate through API results until no more pages.

---

## 4. Loop Control — break, continue, pass

### break — exit the loop immediately

```python
numbers = [1, 3, 7, 2, 8, 5]

for n in numbers:
    if n == 2:
        break           # stop the loop when 2 is found
    print(n)
# prints: 1, 3, 7
```

### continue — skip current iteration, move to next

```python
numbers = [1, 2, 3, 4, 5]

for n in numbers:
    if n % 2 == 0:
        continue        # skip even numbers
    print(n)
# prints: 1, 3, 5
```

### pass — do nothing (placeholder)

```python
for n in range(5):
    if n == 3:
        pass            # nothing happens, loop continues normally
    print(n)
# prints: 0, 1, 2, 3, 4
```

> `pass` is used as a placeholder when a block is required syntactically but you have nothing to write yet.

---

## 5. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| `if/elif/else` | Route records by type, validate field values, check status codes |
| `for` over list | Process each file path, column name, or data row |
| `for` + `enumerate` | Track index while iterating — useful for positional column mapping |
| `range(start, stop, step)` | Generate batch windows, paginate with offsets |
| `while` + counter | Retry logic for DB/API connections |
| `while` + flag | Poll until a pipeline completes or data arrives |
| `break` | Stop scanning once a match is found |
| `continue` | Skip invalid/null records and process the rest |
