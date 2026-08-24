# Day 6 Notes — SQL String Functions

## Topics Covered
1. String basics — literals, concatenation, length
2. Case conversion — UPPER, LOWER, INITCAP
3. Trimming whitespace — TRIM, LTRIM, RTRIM
4. Padding — LPAD, RPAD
5. Searching within strings — POSITION, STRPOS, LIKE, ILIKE
6. Extracting substrings — SUBSTRING, LEFT, RIGHT
7. Replacing and removing — REPLACE, TRANSLATE, REGEXP_REPLACE
8. Splitting strings — SPLIT_PART, STRING_TO_ARRAY
9. Building strings — CONCAT, CONCAT_WS, FORMAT, STRING_AGG
10. Pattern matching — LIKE, ILIKE, SIMILAR TO, ~ (regex)
11. Type conversion — CAST, ::text, TO_CHAR with strings
12. NULL handling in strings — COALESCE, NULLIF, IS NULL
13. Common mistakes and edge cases

---

## 1. String Basics — Literals, Concatenation, Length

In PostgreSQL strings are always wrapped in **single quotes**.
Double quotes are for identifiers (column/table names), never string values.

```sql
SELECT 'Hello World';           -- string literal
SELECT 'It''s a test';          -- escape single quote by doubling it
SELECT E'tab:\there';           -- escape string with \t

-- Concatenation: || operator joins strings
SELECT 'Hello' || ' ' || 'World';    -- 'Hello World'
SELECT first_name || ' ' || last_name AS full_name FROM employees;

-- Length
SELECT LENGTH('Hello World');         -- 11  (characters)
SELECT CHAR_LENGTH('Hello World');    -- 11  (alias, SQL standard)
SELECT BIT_LENGTH('Hello');           -- 40  (bits: 8 per ASCII char)
SELECT OCTET_LENGTH('Hello');         -- 5   (bytes)
```

---

## 2. Case Conversion

```sql
SELECT UPPER('hello world');      -- 'HELLO WORLD'
SELECT LOWER('HELLO WORLD');      -- 'hello world'
SELECT INITCAP('hello world');    -- 'Hello World'  (title case)
SELECT INITCAP('john o''brien');  -- 'John O''Brien'
```

### When to use
- `LOWER` on both sides of a comparison for case-insensitive filter: `LOWER(email) = LOWER('ALICE@EXAMPLE.COM')`
- `INITCAP` for display formatting of free-text name fields
- `UPPER` for generating keys, codes, or matching against fixed-value lookup tables

---

## 3. Trimming Whitespace

```sql
-- TRIM removes the specified character from both ends (default: space)
SELECT TRIM('  hello  ');              -- 'hello'
SELECT TRIM(BOTH ' ' FROM '  hi  ');  -- 'hi'
SELECT TRIM(LEADING ' ' FROM '  hi'); -- 'hi  '  (left only)
SELECT TRIM(TRAILING ' ' FROM 'hi '); -- 'hi'    (right only)

-- Shorthand functions
SELECT LTRIM('   hello');    -- 'hello'    (left trim)
SELECT RTRIM('hello   ');    -- 'hello'    (right trim)
SELECT BTRIM('  hello  ');   -- 'hello'    (both — same as TRIM)

-- Trim a specific character (not just spaces)
SELECT TRIM('x' FROM 'xxxhelloxxx');  -- 'hello'
SELECT LTRIM('000123', '0');          -- '123'   useful for zero-padded IDs
```

---

## 4. Padding — LPAD and RPAD

```sql
-- LPAD(string, length, pad_char) — pad from the LEFT to reach total length
SELECT LPAD('42',   5, '0');   -- '00042'   zero-pad numbers
SELECT LPAD('abc',  6, '*');   -- '***abc'
SELECT LPAD('toolong', 4, '0'); -- 'tool'   truncates if already longer

-- RPAD(string, length, pad_char) — pad from the RIGHT
SELECT RPAD('hello', 10, '.');  -- 'hello.....'
SELECT RPAD('AB', 5, '-');      -- 'AB---'

-- Common use: generate fixed-width codes
SELECT LPAD(emp_id::TEXT, 6, '0') AS emp_code FROM employees;  -- '000001'
```

---

## 5. Searching Within Strings — POSITION and STRPOS

```sql
-- POSITION(substring IN string) — returns index of first match (1-based), 0 if not found
SELECT POSITION('world' IN 'hello world');   -- 7
SELECT POSITION('xyz'   IN 'hello world');   -- 0

-- STRPOS(string, substring) — same result, different argument order
SELECT STRPOS('hello world', 'world');       -- 7
SELECT STRPOS('hello world', 'xyz');         -- 0

-- Practical use: check if a string contains a value
SELECT email FROM customers WHERE POSITION('@' IN email) > 0;
SELECT email FROM customers WHERE STRPOS(email, '@') > 0;
```

---

## 6. Extracting Substrings — SUBSTRING, LEFT, RIGHT

```sql
-- SUBSTRING(string FROM start FOR length)
SELECT SUBSTRING('Hello World' FROM 7 FOR 5);   -- 'World'
SELECT SUBSTRING('Hello World' FROM 1 FOR 5);   -- 'Hello'

-- SUBSTR(string, start, length) — same as SUBSTRING, shorter syntax
SELECT SUBSTR('Hello World', 7, 5);             -- 'World'

-- LEFT(string, n) — first n characters
SELECT LEFT('Hello World', 5);    -- 'Hello'
SELECT LEFT('2024-08-15', 4);     -- '2024'   extract year from date string

-- RIGHT(string, n) — last n characters
SELECT RIGHT('Hello World', 5);   -- 'World'
SELECT RIGHT('user@example.com', 3);  -- 'com'  extract domain extension

-- Combining: extract middle portion
SELECT SUBSTRING('INV-2024-00042' FROM 5 FOR 4);  -- '2024'
SELECT LEFT(RIGHT('INV-2024-00042', 10), 4);       -- '2024'
```

---

## 7. Replacing and Removing — REPLACE, TRANSLATE, REGEXP_REPLACE

```sql
-- REPLACE(string, from, to) — replaces ALL occurrences of from with to
SELECT REPLACE('hello world', 'world', 'SQL');  -- 'hello SQL'
SELECT REPLACE('a-b-c-d', '-', '_');            -- 'a_b_c_d'
SELECT REPLACE('  spaces  ', ' ', '');          -- '  spaces  ' → 'spaces'  (removes spaces)

-- TRANSLATE(string, from_chars, to_chars) — character-by-character replacement
-- Each char in from_chars maps to the same position in to_chars
SELECT TRANSLATE('Hello World', 'aeiou', '*****');  -- 'H*ll* W*rld'
SELECT TRANSLATE('h3ll0 w0rld', '013', 'ois');      -- 'hello world'
-- If to_chars is shorter than from_chars, excess from_chars are deleted
SELECT TRANSLATE('hello!world?', '!?', '');         -- 'helloworld'  (removes ! and ?)

-- REGEXP_REPLACE(string, pattern, replacement, flags)
SELECT REGEXP_REPLACE('Hello  World', '\s+', ' ', 'g');   -- 'Hello World'  (collapse spaces)
SELECT REGEXP_REPLACE('abc123def', '[0-9]+', 'NUM', 'g'); -- 'abcNUMdef'
SELECT REGEXP_REPLACE('2024-08-15', '-', '/', 'g');       -- '2024/08/15'
-- flags: 'g' = replace all, 'i' = case insensitive
```

---

## 8. Splitting Strings — SPLIT_PART and STRING_TO_ARRAY

```sql
-- SPLIT_PART(string, delimiter, position) — split by delimiter, return Nth part (1-based)
SELECT SPLIT_PART('alice@example.com', '@', 1);   -- 'alice'       (before @)
SELECT SPLIT_PART('alice@example.com', '@', 2);   -- 'example.com' (after @)
SELECT SPLIT_PART('2024-08-15', '-', 1);           -- '2024'
SELECT SPLIT_PART('2024-08-15', '-', 2);           -- '08'
SELECT SPLIT_PART('2024-08-15', '-', 3);           -- '15'

-- STRING_TO_ARRAY(string, delimiter) — split into a text array
SELECT STRING_TO_ARRAY('apple,banana,cherry', ',');   -- {apple,banana,cherry}
SELECT STRING_TO_ARRAY('a-b-c', '-');                 -- {a,b,c}

-- Access array element with [index] (1-based)
SELECT (STRING_TO_ARRAY('apple,banana,cherry', ','))[2];  -- 'banana'

-- Unnest array into rows
SELECT UNNEST(STRING_TO_ARRAY('apple,banana,cherry', ',')) AS fruit;
-- Returns 3 rows: apple / banana / cherry
```

---

## 9. Building Strings — CONCAT, CONCAT_WS, FORMAT, STRING_AGG

```sql
-- CONCAT — joins values, NULLs become empty string (unlike ||)
SELECT CONCAT('Hello', ' ', 'World');           -- 'Hello World'
SELECT CONCAT('Hello', NULL, 'World');          -- 'HelloWorld'  (NULL ignored)
SELECT 'Hello' || NULL || 'World';             -- NULL          (|| propagates NULL)

-- CONCAT_WS (with separator) — joins non-NULL values with a separator
SELECT CONCAT_WS(', ', 'Alice', 'Pune', 'Gold');          -- 'Alice, Pune, Gold'
SELECT CONCAT_WS(', ', 'Alice', NULL, 'Gold');            -- 'Alice, Gold'  (NULL skipped)
SELECT CONCAT_WS(' ', first_name, middle_name, last_name); -- skips NULL middle name

-- FORMAT — printf-style string formatting
SELECT FORMAT('Hello %s, you have %s orders', 'Alice', 3);  -- 'Hello Alice, you have 3 orders'
SELECT FORMAT('%s-%s-%s', '2024', '08', '15');               -- '2024-08-15'
SELECT FORMAT('INV-%s', LPAD(order_id::TEXT, 5, '0'));       -- 'INV-00001'

-- STRING_AGG(expression, separator) — aggregate: join all values in a group into one string
SELECT
    dept_id,
    STRING_AGG(first_name, ', ' ORDER BY first_name) AS employees
FROM employees
GROUP BY dept_id;
-- Result: dept 1 → 'Alice, Bob, Carol'
```

---

## 10. Pattern Matching — LIKE, ILIKE, SIMILAR TO, ~ (regex)

```sql
-- LIKE — case sensitive, % = any sequence, _ = exactly one char
SELECT * FROM customers WHERE name LIKE 'A%';         -- starts with A
SELECT * FROM customers WHERE name LIKE '%son';        -- ends with son
SELECT * FROM customers WHERE name LIKE '%ali%';       -- contains ali
SELECT * FROM customers WHERE name LIKE '_____';       -- exactly 5 chars
SELECT * FROM customers WHERE email LIKE '%@gmail.%';  -- gmail emails

-- ILIKE — case insensitive version of LIKE (PostgreSQL extension)
SELECT * FROM customers WHERE name ILIKE 'alice';      -- matches Alice, ALICE, alice
SELECT * FROM customers WHERE email ILIKE '%.COM';     -- matches .com, .COM, .Com

-- NOT LIKE / NOT ILIKE
SELECT * FROM customers WHERE email NOT LIKE '%@hotmail.%';

-- SIMILAR TO — SQL-standard regex (limited, rarely used)
SELECT * FROM customers WHERE name SIMILAR TO '(Alice|Bob|Carol)';
SELECT * FROM customers WHERE phone SIMILAR TO '[0-9]{10}';

-- ~ — PostgreSQL POSIX regex (case sensitive)
-- ~* — case insensitive regex
-- !~ — does NOT match
-- !~* — does NOT match (case insensitive)
SELECT * FROM customers WHERE email ~ '@gmail\.(com|in)$';     -- gmail.com or gmail.in
SELECT * FROM customers WHERE name ~* '^[aeiou]';              -- starts with a vowel
SELECT * FROM customers WHERE phone !~ '^[0-9]+$';             -- phone with non-digits
```

---

## 11. Type Conversion Involving Strings

```sql
-- Cast number to string
SELECT 42::TEXT;                        -- '42'
SELECT CAST(42 AS TEXT);               -- '42'
SELECT 3.14::TEXT;                      -- '3.14'

-- Cast string to number
SELECT '42'::INT;                       -- 42
SELECT '3.14'::NUMERIC;                 -- 3.14
SELECT CAST('42' AS INT);              -- 42

-- TO_CHAR for formatted number → string
SELECT TO_CHAR(1234567.89, '9,999,999.99');  -- '1,234,567.89'
SELECT TO_CHAR(42, '000');                   -- '042'
SELECT TO_CHAR(0.75, '99.99%');              -- ' 75.00%'

-- Concatenating mixed types — must cast first
SELECT 'Order #' || order_id::TEXT FROM orders;
SELECT 'Total: ₹' || total_amount::TEXT FROM orders;
-- OR use CONCAT which auto-converts
SELECT CONCAT('Order #', order_id) FROM orders;
```

---

## 12. NULL Handling in Strings

```sql
-- NULL in || propagates: any || NULL = NULL
SELECT 'Hello' || NULL;              -- NULL (not 'Hello')
SELECT first_name || ' ' || last_name FROM employees;  -- NULL if last_name is NULL

-- Fix with COALESCE
SELECT first_name || ' ' || COALESCE(last_name, '') FROM employees;
SELECT COALESCE(middle_name, 'N/A') AS middle FROM employees;

-- CONCAT ignores NULLs (safer for concatenation)
SELECT CONCAT(first_name, ' ', last_name) FROM employees;  -- skips NULL parts

-- NULLIF — returns NULL if both arguments are equal
SELECT NULLIF(phone, '');         -- returns NULL if phone is empty string
SELECT NULLIF(notes, 'N/A');      -- returns NULL if notes = 'N/A'

-- LENGTH of NULL is NULL
SELECT LENGTH(NULL);              -- NULL (not 0)
SELECT LENGTH(COALESCE(name, '')); -- 0 for NULL names
```

---

## 13. Common Mistakes and Edge Cases

### Mistake 1 — Single quotes vs double quotes
```sql
-- WRONG: double quotes are for identifiers, not strings
SELECT "hello world";    -- tries to find a column named hello world → error

-- RIGHT: always use single quotes for string values
SELECT 'hello world';
```

### Mistake 2 — Case sensitivity in LIKE vs ILIKE
```sql
-- WRONG: LIKE is case-sensitive — this won't find 'alice' or 'ALICE'
WHERE name LIKE 'Alice'    -- only matches exact case 'Alice'

-- RIGHT: use ILIKE for case-insensitive match
WHERE name ILIKE 'alice'
-- OR: normalise first
WHERE LOWER(name) = 'alice'
```

### Mistake 3 — POSITION returns 0 (not NULL) when not found
```sql
-- This is safe — POSITION returns 0 not NULL
WHERE POSITION('@' IN email) > 0    -- correct: finds emails with @
WHERE POSITION('@' IN email) = 0    -- finds emails WITHOUT @ (data quality)
```

### Mistake 4 — SPLIT_PART returns empty string (not NULL) for missing parts
```sql
SELECT SPLIT_PART('alice@example.com', '@', 3);   -- '' (empty string, not NULL)
-- Use NULLIF to convert empty to NULL
SELECT NULLIF(SPLIT_PART('alice@example.com', '@', 3), '');  -- NULL
```

### Mistake 5 — LENGTH counts characters, OCTET_LENGTH counts bytes
```sql
-- For multi-byte UTF-8 characters these differ
SELECT LENGTH('café');          -- 4 (characters)
SELECT OCTET_LENGTH('café');    -- 5 (bytes — 'é' is 2 bytes in UTF-8)
```

### Mistake 6 — REPLACE does not use regex; use REGEXP_REPLACE for patterns
```sql
-- REPLACE looks for exact literal substring
SELECT REPLACE('Hello  World', '  ', ' ');   -- 'Hello World' (only replaces exactly 2 spaces)

-- REGEXP_REPLACE handles variable whitespace
SELECT REGEXP_REPLACE('Hello   World', '\s+', ' ', 'g');  -- 'Hello World'
```

---

## String Function Quick Reference

| Function | Purpose | Example |
|----------|---------|---------|
| `LENGTH(s)` | Character count | `LENGTH('hello')` → `5` |
| `UPPER(s)` | All uppercase | `UPPER('hi')` → `'HI'` |
| `LOWER(s)` | All lowercase | `LOWER('HI')` → `'hi'` |
| `INITCAP(s)` | Title case | `INITCAP('hello world')` → `'Hello World'` |
| `TRIM(s)` | Remove leading/trailing spaces | `TRIM('  hi  ')` → `'hi'` |
| `LTRIM(s)` | Remove leading spaces/chars | `LTRIM('  hi')` → `'hi'` |
| `RTRIM(s)` | Remove trailing spaces/chars | `RTRIM('hi  ')` → `'hi'` |
| `LPAD(s,n,c)` | Left-pad to length n | `LPAD('5',3,'0')` → `'005'` |
| `RPAD(s,n,c)` | Right-pad to length n | `RPAD('hi',5,'.')` → `'hi...'` |
| `POSITION(sub IN s)` | Index of first match (0 = not found) | `POSITION('o' IN 'hello')` → `5` |
| `STRPOS(s, sub)` | Same as POSITION, different syntax | `STRPOS('hello','o')` → `5` |
| `SUBSTRING(s FROM n FOR len)` | Extract substring | `SUBSTRING('hello' FROM 2 FOR 3)` → `'ell'` |
| `LEFT(s,n)` | First n chars | `LEFT('hello',3)` → `'hel'` |
| `RIGHT(s,n)` | Last n chars | `RIGHT('hello',3)` → `'llo'` |
| `REPLACE(s,from,to)` | Replace all literal occurrences | `REPLACE('a-b','−','_')` → `'a_b'` |
| `TRANSLATE(s,from,to)` | Char-by-char replacement | `TRANSLATE('hi','i','o')` → `'ho'` |
| `REGEXP_REPLACE(s,p,r,f)` | Regex-based replace | `REGEXP_REPLACE('a1b2','[0-9]','#','g')` → `'a#b#'` |
| `SPLIT_PART(s,del,n)` | Nth token after split | `SPLIT_PART('a,b,c',',',2)` → `'b'` |
| `STRING_TO_ARRAY(s,del)` | Split to array | `STRING_TO_ARRAY('a,b',',')` → `{a,b}` |
| `CONCAT(...)` | Join, NULLs become empty | `CONCAT('a',NULL,'b')` → `'ab'` |
| `CONCAT_WS(sep,...)` | Join with separator, skip NULLs | `CONCAT_WS(',','a',NULL,'b')` → `'a,b'` |
| `FORMAT(fmt,...)` | printf-style formatting | `FORMAT('Hi %s',name)` |
| `STRING_AGG(expr,sep)` | Aggregate: join group into one string | `STRING_AGG(name,', ')` |
| `LIKE` | Pattern match (case sensitive) | `name LIKE 'A%'` |
| `ILIKE` | Pattern match (case insensitive) | `name ILIKE 'alice'` |
| `~` | POSIX regex match | `email ~ '@gmail\.com$'` |
| `COALESCE(s,'default')` | Replace NULL with default | `COALESCE(nickname,'N/A')` |
| `NULLIF(s,'')` | Return NULL if equal | `NULLIF(phone,'')` → NULL |

---

## DE Relevance Summary

| Concept | Data Engineering Use |
|---------|---------------------|
| `LOWER` / `UPPER` | Normalising keys before joining across systems with inconsistent casing |
| `TRIM` / `REPLACE` | Cleaning raw ingested data — removing stray whitespace, special chars |
| `REGEXP_REPLACE` | Masking PII (emails, phones) in data lake layers |
| `SPLIT_PART` | Parsing delimited fields from flat files (CSV, TSV with embedded delimiters) |
| `STRING_AGG` | Collapsing one-to-many into arrays/lists for downstream JSON serialisation |
| `LPAD` | Generating zero-padded keys for fixed-width file formats |
| `CONCAT_WS` | Building composite keys (dept_id + '-' + emp_id) for dimension tables |
| `POSITION` / `STRPOS` | Detecting malformed fields (missing @, missing delimiter) |
| `ILIKE` / `~` | Data-quality checks — pattern validation on email, phone, postal codes |
| `NULLIF(col,'')` | Converting empty-string placeholders from CSVs back to proper NULLs |
| `TO_CHAR` + number | Formatting partition key strings (e.g. `LPAD(month,'2','0')` for folder paths) |
