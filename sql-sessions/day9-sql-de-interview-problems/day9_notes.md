# Day 9 Notes — UNION, UNION ALL, INTERSECT, EXCEPT

> **Revision-style sheet** — use alongside `day9_practice.sql`.

---

## The Core Idea

All four operators **combine result sets from two or more SELECT statements**.
Rules that apply to all of them:

1. Both SELECTs must return the **same number of columns**
2. Corresponding columns must have **compatible data types**
3. Column **names come from the first SELECT** only
4. `ORDER BY` goes **once at the very end** — never inside individual parts

---

## UNION ALL — keep everything, no dedup

```sql
SELECT name, department FROM employees_india
UNION ALL
SELECT name, department FROM employees_us;
```

- Returns ALL rows from both sides — **duplicates included**
- Faster than UNION (no sort/dedup step)
- Use when duplicates are acceptable or expected (combining channels, logs)

---

## UNION — deduplicate across both sides

```sql
SELECT name, department FROM employees_india
UNION
SELECT name, department FROM employees_us;
```

- Returns only **distinct rows** across both sides
- Slower — does an implicit `DISTINCT` (requires sort)
- Use when you need unique records from multiple sources

---

## INTERSECT — only rows that exist in BOTH

```sql
SELECT product FROM this_year_sales
INTERSECT
SELECT product FROM last_year_sales;
```

- Returns rows that appear in **both** result sets
- Automatically deduplicates
- Use for finding common elements between two datasets

---

## EXCEPT — rows in first set but NOT in second

```sql
-- New products (in this year but not last year)
SELECT product FROM this_year_sales
EXCEPT
SELECT product FROM last_year_sales;

-- Discontinued products (in last year but not this year)
SELECT product FROM last_year_sales
EXCEPT
SELECT product FROM this_year_sales;
```

- Returns rows from the **first** SELECT that do NOT appear in the second
- Order matters — flip the two SELECTs to get the opposite set
- Automatically deduplicates

---

## Side-by-side comparison

| Operator | Duplicates | What it returns |
|----------|-----------|-----------------|
| `UNION ALL` | Kept | All rows from both sides |
| `UNION` | Removed | Distinct rows from both sides |
| `INTERSECT` | Removed | Rows present in both sides |
| `EXCEPT` | Removed | Rows in first side only |

---

## Common Patterns

### Combine two data sources with a tag
```sql
SELECT 'Online'  AS channel, order_id, product, amount FROM online_orders
UNION ALL
SELECT 'Offline' AS channel, order_id, product, amount FROM offline_orders
ORDER BY amount DESC;
```

### Aggregate across both sources
```sql
SELECT category, SUM(revenue) AS total
FROM (
    SELECT category, revenue FROM this_year_sales
    UNION ALL
    SELECT category, revenue FROM last_year_sales
) combined
GROUP BY category;
```

### UNION ALL + ROW_NUMBER dedup (keep best version)
```sql
WITH combined AS (
    SELECT 1 AS priority, * FROM online_orders
    UNION ALL
    SELECT 2 AS priority, * FROM offline_orders
),
deduped AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY customer_id, product, amount, order_date
        ORDER BY priority
    ) AS rn
    FROM combined
)
SELECT * FROM deduped WHERE rn = 1;
```
Use when two sources can have the same record and you want to keep one version (e.g. online wins over offline).

---

## Common Mistakes

| Mistake | Example | Fix |
|---------|---------|-----|
| Different column count | `SELECT a, b UNION SELECT x` | Both sides must have same column count |
| ORDER BY inside a part | `SELECT a FROM t1 ORDER BY a UNION ...` | Move ORDER BY to the very end |
| EXCEPT order matters | `A EXCEPT B` ≠ `B EXCEPT A` | Flip sides to get the opposite result |
| Using UNION when UNION ALL is enough | Slow dedup on millions of rows | Use UNION ALL unless you need distinct |
| Type mismatch | `SELECT id UNION SELECT name` | Cast to compatible type: `id::TEXT` |

---

## DE Relevance

| Pattern | Use case |
|---------|---------|
| `UNION ALL` | Merging logs, events, orders from multiple sources/regions |
| `UNION` | Deduplicating customer lists from two systems |
| `INTERSECT` | Finding customers who bought from both online and offline |
| `EXCEPT` | Finding records in staging but not in production (reconciliation) |
| `UNION ALL` + `GROUP BY` | Aggregating across multiple partitions or time periods |
| `UNION ALL` + `ROW_NUMBER` | Dedup while keeping priority source |
