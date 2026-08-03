# Day 1 Practice Problems — Python Fundamentals

Solve each problem in a `.py` file. Do not look up solutions — work through the logic yourself first.

---

## Variables & Data Types

**P1. Type Inspector**
Create five variables — one of each type: `int`, `float`, `str`, `bool`, and `None`.
Print the value and type of each on a single line.
Expected format: `44 <class 'int'>`

---

**P2. Type Casting Pipeline**
You receive data from a CSV as strings:
```python
raw_id     = "101"
raw_salary = "75000.50"
raw_active = "True"
```
Cast each to its correct Python type (`int`, `float`, `bool`) and print them with their new types.

> Why this matters: Every value read from a CSV or API response comes in as a string. Data engineers must cast before any calculation or comparison.

---

**P3. Input & Output**
Ask the user for their name and age using `input()`.
Print: `Hello <name>, you will be <age+10> in 10 years.`
Make sure age arithmetic works (hint: cast the input).

---

## Arithmetic Operators

**P4. Batch Partitioner**
You have 130 records and want to split them into batches of 15.
- How many complete batches can you make?
- How many records are left over in the last incomplete batch?
Use only `//` and `%` operators.

---

**P5. Operator Explorer**
Given `a = 17` and `b = 5`, print the result of all seven arithmetic operators (`+`, `-`, `*`, `/`, `//`, `%`, `**`) with a label.
Expected format: `17 // 5 = 3`

---

## Comparison & Logical Operators

**P6. Salary Filter**
Given these variables:
```python
salary     = 85000
experience = 3
department = "Engineering"
```
Write `if/else` blocks to check:
1. Is salary above 80000 **and** experience greater than 2?
2. Is department either "Engineering" **or** "Data"?
3. Is salary **not** equal to 90000?
Print a descriptive message for each result.

---

**P7. Grade Classifier**
Ask the user to enter a score (0–100).
Print the grade based on these rules:
- 90 and above → `A`
- 80–89 → `B`
- 70–79 → `C`
- 60–69 → `D`
- Below 60 → `F`
Use `and` to define the ranges.

---

## Membership & Identity Operators

**P8. Column Validator**
You have a required schema:
```python
required_columns = ["id", "name", "salary", "department", "hire_date"]
```
Check if each of these columns exists in the schema using `in`:
- `"salary"`
- `"age"`
- `"hire_date"`
- `"email"`
Print `"<column>: present"` or `"<column>: missing"` for each.

> Why this matters: Before loading data into a pipeline, you always validate that expected columns are present.

---

**P9. None / NULL Check**
Given a list of values:
```python
values = [100, None, 250, None, 400]
```
Loop through the list. For each value:
- If it `is None`, print `"NULL found — skip"`
- Otherwise print the value

> Why this matters: NULL handling is one of the most common sources of bugs in data pipelines.

---

**P10. Identity vs Equality**
```python
x = [1, 2, 3]
y = [1, 2, 3]
z = x
```
Without running the code, predict the output of:
- `x == y`
- `x is y`
- `x == z`
- `x is z`

Then run it and verify. Explain in a comment why `x is y` gives a different result than `x == y`.

---

## Lists — Indexing, Slicing, Methods

**P11. List Explorer**
Create this list:
```python
pipeline_steps = ["ingest", "validate", "transform", "aggregate", "load"]
```
Answer using indexing/slicing — no loops:
1. Print the first step
2. Print the last step
3. Print the first three steps
4. Print the last two steps
5. Print every other step (step = 2)

---

**P12. Nested List Drill**
```python
employee = ["Alice", 32, 95000.0, ["Python", "SQL", "PySpark"]]
```
1. Print the employee's name
2. Print her salary
3. Print her second skill
4. Print the number of skills she has

---

**P13. Dynamic Schema Builder**
Start with an empty list `schema = []`.
Using only list methods (`append`, `remove`, `pop`):
1. Add columns: `"id"`, `"name"`, `"salary"`, `"dept"`, `"temp_col"`
2. Remove `"temp_col"` (it was added by mistake)
3. Print the final schema and its length

---

**P14. Batch Slicer**
```python
records = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
```
Using slicing only (no loops):
1. Extract the first batch of 3 records
2. Extract the second batch of 3 records
3. Extract the last 4 records
4. Extract every 3rd record from the full list

---

**P15. Mixed-Type List Stats**
```python
data = [45, 78.5, 90, 23.3, 67, 55.5, 88, 12]
```
Find:
1. Total number of elements
2. The first and last value
3. The middle slice (index 2 to 6)
4. The list in reverse using slicing (`[::-1]`)

---

## Bonus / Challenge

**P16. Mini Data Validator**
You receive one record as a dictionary:
```python
record = {
    "id":         "101",
    "name":       "Alice",
    "salary":     "95000",
    "department": "Engineering",
    "active":     "True"
}
```
Write code that:
1. Checks all required keys are present (`"id"`, `"name"`, `"salary"`, `"department"`) using `in`
2. Casts `"id"` to `int`, `"salary"` to `float`, `"active"` to `bool`
3. Checks if `salary > 80000` and `active is True`
4. Prints a summary: `"Record 101 — Alice | Salary: 95000.0 | Active: True | High earner: True"`

> This pattern — validate schema → cast types → apply business rules — is the core of every data ingestion pipeline.
