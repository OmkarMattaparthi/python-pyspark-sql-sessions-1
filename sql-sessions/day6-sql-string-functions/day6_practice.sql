-- =============================================================
-- Day 6 Practice — SQL String Functions
-- =============================================================
-- Standalone: no dependency on any previous day's file.
-- Run this file top-to-bottom on any clean PostgreSQL database.
--
-- Tables created here:
--   store.customers    — customer_id, first_name, last_name, nickname, email, phone, city, country, signup_date
--   store.products     — product_id, product_name, category, brand, sku, price, tags
--   store.orders       — order_id, customer_id, order_ref, order_date, amount
--   store.employees    — emp_id, first_name, middle_name, last_name, department
--   store.raw_imports  — id, raw_name, raw_email, raw_phone, raw_notes  (intentionally messy)


-- =============================================================
-- DATA SETUP — schema + purposeful data for all String demos
-- =============================================================
--
-- What the data is designed to show:
--   Case functions     → mixed-case names, emails needing normalisation
--   TRIM / LPAD        → raw_imports has leading spaces, zero-pad IDs
--   SPLIT_PART         → emails with @, SKUs with segments, tag lists
--   REPLACE/REGEXP     → phone numbers with hyphens, multi-space notes
--   STRING_AGG         → multiple orders per customer, tags per category
--   NULL handling      → NULL middle names, empty-string placeholders
--   Pattern matching   → malformed emails, non-digit phone characters
-- -------------------------------------------------------------


-- Step 1: Drop and recreate schema cleanly
DROP SCHEMA IF EXISTS store CASCADE;
CREATE SCHEMA store;


-- Step 2: Customers — mix of good data, NULLs, and edge cases
--
-- Deliberate variety:
--   Alice and Bob   → well-formed data
--   Carol           → no nickname, NULL country
--   David           → NULL middle_name (employee table mirrors this)
--   Eva             → email missing @  ← data quality demo
--   Frank           → phone with non-digits  ← data quality demo
--   Grace           → NULL city

CREATE TABLE store.customers (
    customer_id  SERIAL       PRIMARY KEY,
    first_name   VARCHAR(50),
    last_name    VARCHAR(50),
    nickname     VARCHAR(50),
    email        VARCHAR(150),
    phone        VARCHAR(20),
    city         VARCHAR(50),
    country      VARCHAR(50),
    signup_date  DATE
);

INSERT INTO store.customers
    (first_name, last_name, nickname, email, phone, city, country, signup_date)
VALUES
    ('Alice',  'Cooper',  'Ally',  'alice.cooper@gmail.com',   '9876543210',  'Mumbai',    'India',   '2021-06-15'),  -- 1
    ('Bob',    'Sharma',  'Bobby', 'bob.sharma@yahoo.com',     '9123456789',  'Pune',      'India',   '2022-03-01'),  -- 2
    ('Carol',  'Mendes',  NULL,    'carol.mendes@outlook.com', '9000012345',  'Bangalore', NULL,      '2023-01-10'),  -- 3  NULL country
    ('David',  'Nair',    'Dave',  'david.nair@gmail.com',     '8888877777',  'Chennai',   'India',   '2020-11-20'),  -- 4
    ('Eva',    'Singh',   NULL,    'evasingh.noatsign.com',    '7777766666',  'Delhi',     'India',   '2023-07-05'),  -- 5  BAD email
    ('Frank',  'Patel',   'Franky','frank.patel@gmail.com',    '98-765-43210','Hyderabad', 'India',   '2024-02-14'),  -- 6  phone with hyphens
    ('Grace',  'Thomas',  'Gracie','grace.thomas@hotmail.com', '6666655555',  NULL,        'India',   '2022-08-30'),  -- 7  NULL city
    ('Henry',  'Das',     NULL,    'henry.das@company.in',     '5555544444',  'Kolkata',   'India',   '2021-09-09');  -- 8


-- Step 3: Products — with SKU pattern and comma-separated tags
--
-- SKU format: <3-letter category>-<4-letter brand>-<4-digit number>
-- Tags: comma-separated, no spaces

CREATE TABLE store.products (
    product_id    SERIAL        PRIMARY KEY,
    product_name  VARCHAR(100)  NOT NULL,
    category      VARCHAR(50),
    brand         VARCHAR(50),
    sku           VARCHAR(30),
    price         NUMERIC(10,2),
    tags          TEXT           -- comma-separated e.g. 'wireless,bluetooth,audio'
);

INSERT INTO store.products (product_name, category, brand, sku, price, tags) VALUES
    ('Laptop Pro 15',        'Electronics', 'Sony',    'ELE-SONY-0001', 80000.00, 'laptop,portable,work'),
    ('Wireless Mouse',       'Electronics', 'Logitech','ELE-LOGI-0002',  1500.00, 'wireless,mouse,ergonomic'),
    ('Office Chair',         'Furniture',   'Featherlite','FUR-FEAT-0001',12000.00,'ergonomic,seating,office'),
    ('Standing Desk',        'Furniture',   'Godrej',  'FUR-GODR-0002', 22000.00, 'adjustable,desk,office'),
    ('Notebook Pack 200pg',  'Stationery',  'Classmate','STA-CLAS-0001',   400.00, 'paper,writing,school'),
    ('Monitor 27" 4K',       'Electronics', 'LG',      'ELE-LG00-0003', 20000.00, 'display,4k,widescreen'),
    ('Desk Lamp LED',        'Furniture',   'Philips', 'FUR-PHIL-0003',  2500.00, 'lighting,led,office'),
    ('Ballpoint Pen Set',    'Stationery',  'Parker',  'STA-PARK-0002',   250.00, 'pen,writing,premium');


-- Step 4: Orders — with a structured order_ref string
--
-- order_ref format: ORD-<YYYY>-<MM>-<DD>-<NNN>

CREATE TABLE store.orders (
    order_id     SERIAL        PRIMARY KEY,
    customer_id  INT           REFERENCES store.customers(customer_id),
    order_ref    VARCHAR(30),
    order_date   DATE,
    amount       NUMERIC(10,2)
);

INSERT INTO store.orders (customer_id, order_ref, order_date, amount) VALUES
    (1, 'ORD-2024-01-05-001', '2024-01-05', 80000.00),
    (1, 'ORD-2024-02-10-002', '2024-02-10',  1500.00),
    (2, 'ORD-2024-01-20-003', '2024-01-20', 20000.00),
    (3, 'ORD-2024-03-01-004', '2024-03-01',   400.00),
    (4, 'ORD-2024-01-15-005', '2024-01-15', 80000.00),
    (4, 'ORD-2024-02-20-006', '2024-02-20', 12000.00),
    (6, 'ORD-2024-03-10-007', '2024-03-10',  2500.00),
    (8, 'ORD-2024-04-01-008', '2024-04-01',  1500.00);


-- Step 5: Employees — with NULL and empty-string middle names
CREATE TABLE store.employees (
    emp_id       SERIAL       PRIMARY KEY,
    first_name   VARCHAR(50),
    middle_name  VARCHAR(50),   -- sometimes NULL, sometimes ''
    last_name    VARCHAR(50),
    department   VARCHAR(50)
);

INSERT INTO store.employees (first_name, middle_name, last_name, department) VALUES
    ('Raj',     'Kumar',  'Mehta',   'Engineering'),  -- emp_id = 1  has middle name
    ('Priya',   NULL,     'Sharma',  'Marketing'),    -- emp_id = 2  NULL middle name
    ('Amit',    '',       'Patel',   'HR'),            -- emp_id = 3  empty-string middle name
    ('Sunita',  'Devi',   'Nair',    'Finance'),       -- emp_id = 4
    ('Arjun',   NULL,     'Das',     'Engineering');   -- emp_id = 5  NULL middle name


-- Step 6: Raw imports table — intentionally messy for cleaning demos
--
-- Deliberate problems:
--   raw_name  → leading/trailing spaces
--   raw_email → uppercase, extra spaces
--   raw_phone → leading zeros, hyphens, wrong length
--   raw_notes → multiple consecutive spaces, 'N/A' placeholders

CREATE TABLE store.raw_imports (
    id         SERIAL PRIMARY KEY,
    raw_name   TEXT,
    raw_email  TEXT,
    raw_phone  TEXT,
    raw_notes  TEXT
);

INSERT INTO store.raw_imports (raw_name, raw_email, raw_phone, raw_notes) VALUES
    ('  Alice Smith  ',  'ALICE.SMITH@GMAIL.COM  ',  '09876543210', 'First  time  buyer.  Prefers  email.'),
    ('Bob   Jones',      '  bob.jones@yahoo.com',    '98-765-43210', 'Repeat  customer.   High  value.'),
    ('  carol white',    'carol.white@OUTLOOK.COM',  '0091-9000012345', 'N/A'),
    ('DAVID BROWN  ',    '  DAVID.BROWN@GMAIL.COM ', '88888-77777', '-'),
    ('eve   green',      'evegreen@nodot',           '777776666',   ''),
    ('Frank  Black',     'frank.black@company.in  ', '06666655555', 'Bulk   order   customer.');


-- Sanity check: row counts
-- Expected: customers=8, products=8, orders=8, employees=5, raw_imports=6
SELECT 'customers'   AS tbl, COUNT(*) AS rows FROM store.customers
UNION ALL
SELECT 'products',   COUNT(*) FROM store.products
UNION ALL
SELECT 'orders',     COUNT(*) FROM store.orders
UNION ALL
SELECT 'employees',  COUNT(*) FROM store.employees
UNION ALL
SELECT 'raw_imports',COUNT(*) FROM store.raw_imports;


-- =============================================================
-- SECTION 1 — LENGTH, UPPER, LOWER, INITCAP
-- =============================================================

-- LENGTH counts characters (not bytes).
-- CHAR_LENGTH is the SQL standard alias — identical result.
-- UPPER / LOWER convert all characters.
-- INITCAP capitalises the first letter of every word.

SELECT
    first_name,
    last_name,
    LENGTH(first_name)                         AS first_len,
    LENGTH(last_name)                          AS last_len,
    LENGTH(first_name) + LENGTH(last_name)     AS total_chars,
    UPPER(first_name)                          AS upper_name,
    LOWER(email)                               AS email_lower,
    INITCAP(city)                              AS city_title
FROM store.customers
ORDER BY total_chars DESC;


-- LOWER in WHERE for case-insensitive comparison
-- Do NOT use ILIKE if you want to demonstrate LOWER explicitly

SELECT first_name, email
FROM store.customers
WHERE LOWER(first_name) = 'alice';


-- Find customers whose name starts with a vowel — normalise case first
SELECT first_name, last_name
FROM store.customers
WHERE LOWER(first_name) LIKE 'a%'
   OR LOWER(first_name) LIKE 'e%'
   OR LOWER(first_name) LIKE 'i%'
   OR LOWER(first_name) LIKE 'o%'
   OR LOWER(first_name) LIKE 'u%';


-- =============================================================
-- SECTION 2 — TRIM, LTRIM, RTRIM
-- =============================================================

-- TRIM removes leading and trailing spaces (default) or a specified character.
-- LTRIM removes only from the left; RTRIM only from the right.
-- This is the first step when cleaning raw ingested data.

-- See the raw data before cleaning
SELECT id, raw_name, raw_email, raw_phone FROM store.raw_imports;

-- Clean: trim spaces from name and email
SELECT
    id,
    raw_name,
    TRIM(raw_name)         AS name_trimmed,
    raw_email,
    TRIM(raw_email)        AS email_trimmed,
    LOWER(TRIM(raw_email)) AS email_clean     -- trim then lowercase
FROM store.raw_imports;


-- LTRIM / RTRIM for directional trimming
SELECT
    '   leading'            AS original,
    LTRIM('   leading')     AS after_ltrim,
    RTRIM('trailing   ')    AS after_rtrim,
    BTRIM('  both  ')       AS after_btrim;


-- Trim a specific character — remove leading zeros from phone
SELECT
    raw_phone,
    LTRIM(raw_phone, '0')   AS phone_no_leading_zero
FROM store.raw_imports;


-- =============================================================
-- SECTION 3 — LPAD and RPAD
-- =============================================================

-- LPAD pads from the left; RPAD pads from the right.
-- Most common use: zero-pad IDs for fixed-width codes or file outputs.
-- If the string is already longer than target length, it is TRUNCATED.

SELECT
    emp_id,
    first_name,
    LPAD(emp_id::TEXT, 6, '0')           AS emp_code,      -- '000001'
    RPAD(department, 15, '.')            AS dept_padded    -- 'Engineering....'
FROM store.employees;


-- Generate invoice codes: INV- prefix + zero-padded order_id
SELECT
    order_id,
    'INV-' || LPAD(order_id::TEXT, 5, '0')   AS invoice_code  -- 'INV-00001'
FROM store.orders;


-- LPAD truncates when string is longer than target
SELECT
    LPAD('toolong', 4, '0')   AS truncated_lpad;   -- 'tool'


-- =============================================================
-- SECTION 4 — POSITION and STRPOS
-- =============================================================

-- POSITION(sub IN string) and STRPOS(string, sub) both return
-- the 1-based index of the first occurrence, or 0 if not found.
-- Never return NULL — always 0 or a positive integer.

SELECT
    email,
    POSITION('@' IN email)      AS at_position,
    STRPOS(email, '.')          AS first_dot_position
FROM store.customers;


-- Data quality: find emails missing the @ sign (POSITION returns 0)
SELECT first_name, email
FROM store.customers
WHERE POSITION('@' IN email) = 0;


-- Count how many dots in an email using LENGTH + REPLACE trick
-- Remove all dots and compare lengths → difference = dot count
SELECT
    email,
    LENGTH(email) - LENGTH(REPLACE(email, '.', ''))  AS dot_count
FROM store.customers
ORDER BY dot_count DESC;


-- =============================================================
-- SECTION 5 — SUBSTRING, LEFT, RIGHT
-- =============================================================

-- SUBSTRING(string FROM start FOR length) — extract a portion.
-- LEFT(string, n) — first n characters.
-- RIGHT(string, n) — last n characters.
-- All are 1-based (first character is position 1).

-- Extract username and domain from email
SELECT
    email,
    LEFT(email, POSITION('@' IN email) - 1)                              AS username,
    SUBSTRING(email FROM POSITION('@' IN email) + 1)                     AS domain
FROM store.customers
WHERE POSITION('@' IN email) > 0;   -- only well-formed emails


-- Parse SKU: CAT-BRAND-NNNN
-- ELE-SONY-0001 → category=ELE, brand=SONY, number=0001
SELECT
    sku,
    LEFT(sku, 3)                    AS category_code,   -- 'ELE'
    SUBSTRING(sku FROM 5 FOR 4)     AS brand_code,      -- 'SONY'
    RIGHT(sku, 4)                   AS item_number      -- '0001'
FROM store.products;


-- Extract year from date string (if stored as text)
SELECT
    order_ref,
    LEFT(order_ref, 3)              AS prefix,          -- 'ORD'
    SUBSTRING(order_ref FROM 5 FOR 4) AS ref_year,      -- '2024'
    SUBSTRING(order_ref FROM 10 FOR 2) AS ref_month,    -- '08'
    SUBSTRING(order_ref FROM 13 FOR 2) AS ref_day       -- '15'
FROM store.orders;


-- =============================================================
-- SECTION 6 — REPLACE, TRANSLATE, REGEXP_REPLACE
-- =============================================================

-- REPLACE(string, from_literal, to_literal) — replaces exact substring.
-- TRANSLATE(string, from_chars, to_chars)   — char-by-char replacement.
-- REGEXP_REPLACE(string, pattern, repl, flags) — regex-powered replace.

-- REPLACE: remove hyphens from phone numbers
SELECT
    raw_phone,
    REPLACE(raw_phone, '-', '')     AS phone_no_hyphens
FROM store.raw_imports;


-- REPLACE: remove all spaces
SELECT
    raw_name,
    REPLACE(TRIM(raw_name), ' ', '_')  AS name_underscored
FROM store.raw_imports;


-- TRANSLATE: character-by-character replacement
-- Replace vowels with * for a masking demo
SELECT
    first_name,
    TRANSLATE(LOWER(first_name), 'aeiou', '*****')  AS masked_name
FROM store.customers;


-- TRANSLATE: remove unwanted characters (make to_chars shorter)
-- Remove all punctuation from notes
SELECT
    raw_notes,
    TRANSLATE(raw_notes, '.,!?;:', '')  AS notes_clean
FROM store.raw_imports
WHERE raw_notes NOT IN ('N/A', '-', '');


-- REGEXP_REPLACE: collapse multiple spaces into one
-- 'g' flag = replace ALL occurrences, not just first
SELECT
    raw_notes,
    REGEXP_REPLACE(raw_notes, '\s+', ' ', 'g')   AS notes_single_spaced
FROM store.raw_imports;


-- REGEXP_REPLACE: remove all non-digit characters from phone
SELECT
    raw_phone,
    REGEXP_REPLACE(raw_phone, '[^0-9]', '', 'g')  AS digits_only
FROM store.raw_imports;


-- REGEXP_REPLACE: mask sensitive email — keep first char + @domain
-- 'alice.cooper@gmail.com' → 'a***@gmail.com'
SELECT
    email,
    CONCAT(
        LEFT(email, 1),
        '***',
        SUBSTRING(email FROM POSITION('@' IN email))
    ) AS masked_email
FROM store.customers
WHERE POSITION('@' IN email) > 0;


-- =============================================================
-- SECTION 7 — SPLIT_PART and STRING_TO_ARRAY / UNNEST
-- =============================================================

-- SPLIT_PART(string, delimiter, position) — returns the Nth field.
-- Position is 1-based. Returns empty string if field doesn't exist.
-- STRING_TO_ARRAY converts to a PostgreSQL array.
-- UNNEST expands an array into individual rows.

-- Split email into username and domain using SPLIT_PART
SELECT
    email,
    SPLIT_PART(email, '@', 1)   AS username,    -- before @
    SPLIT_PART(email, '@', 2)   AS domain       -- after @
FROM store.customers;


-- Split SKU into components
SELECT
    sku,
    SPLIT_PART(sku, '-', 1)     AS cat_code,    -- 'ELE'
    SPLIT_PART(sku, '-', 2)     AS brand_code,  -- 'SONY'
    SPLIT_PART(sku, '-', 3)     AS item_num     -- '0001'
FROM store.products;


-- Tags: comma-separated → show first 3 tags as separate columns
SELECT
    product_name,
    tags,
    SPLIT_PART(tags, ',', 1)    AS tag_1,
    SPLIT_PART(tags, ',', 2)    AS tag_2,
    SPLIT_PART(tags, ',', 3)    AS tag_3
FROM store.products;


-- UNNEST: expand tags into one row per tag
-- Each product appears once per tag
SELECT
    product_name,
    category,
    UNNEST(STRING_TO_ARRAY(tags, ','))   AS tag
FROM store.products
ORDER BY product_name, tag;


-- Count of tags per product
SELECT
    product_name,
    ARRAY_LENGTH(STRING_TO_ARRAY(tags, ','), 1)  AS tag_count
FROM store.products
ORDER BY tag_count DESC;


-- =============================================================
-- SECTION 8 — CONCAT, CONCAT_WS, FORMAT, STRING_AGG
-- =============================================================

-- || propagates NULL: 'a' || NULL = NULL
-- CONCAT ignores NULLs: CONCAT('a', NULL, 'b') = 'ab'
-- CONCAT_WS skips NULL elements and only adds separator between non-NULLs
-- FORMAT is printf-style — great for structured labels

-- || vs CONCAT: NULL difference
SELECT
    'Hello' || ' ' || NULL || 'World'                   AS pipe_null,    -- NULL
    CONCAT('Hello', ' ', NULL, 'World')                 AS concat_null;  -- 'Hello World'


-- CONCAT_WS: build full name skipping NULL/empty middle name
SELECT
    emp_id,
    first_name,
    middle_name,
    last_name,
    CONCAT_WS(' ', first_name, NULLIF(middle_name, ''), last_name)  AS full_name
FROM store.employees;


-- CONCAT_WS: build address string — gracefully handle NULL city/country
SELECT
    first_name,
    city,
    country,
    CONCAT_WS(', ', city, country)  AS location   -- skips NULL
FROM store.customers;


-- FORMAT: structured label for each product
SELECT
    product_id,
    FORMAT('[%s] %s — ₹%s', category, product_name, price)  AS product_label
FROM store.products;


-- FORMAT: generate invoice code
SELECT
    order_id,
    customer_id,
    FORMAT('INV-%s-%s', EXTRACT(YEAR FROM order_date)::TEXT, LPAD(order_id::TEXT, 5, '0')) AS invoice_ref
FROM store.orders;


-- STRING_AGG: aggregate rows — products per category as one string
SELECT
    category,
    STRING_AGG(product_name, ', ' ORDER BY product_name)  AS product_list
FROM store.products
GROUP BY category;


-- STRING_AGG: orders per customer — list order_ids
SELECT
    c.first_name,
    COALESCE(
        STRING_AGG(o.order_id::TEXT, ' | ' ORDER BY o.order_id),
        'No orders'
    ) AS order_list
FROM store.customers c
LEFT JOIN store.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name
ORDER BY c.first_name;


-- STRING_AGG: all tags across products per category (unnest first)
SELECT
    category,
    STRING_AGG(tag, ', ' ORDER BY tag)  AS all_tags
FROM (
    SELECT category, UNNEST(STRING_TO_ARRAY(tags, ',')) AS tag
    FROM store.products
) expanded
GROUP BY category;


-- =============================================================
-- SECTION 9 — Pattern Matching: LIKE, ILIKE, ~
-- =============================================================

-- LIKE   — case-sensitive, % = any chars, _ = exactly one char
-- ILIKE  — case-insensitive version (PostgreSQL extension)
-- ~      — POSIX regex, case-sensitive
-- ~*     — POSIX regex, case-insensitive
-- !~     — does NOT match (case-sensitive)
-- !~*    — does NOT match (case-insensitive)

-- LIKE: names starting with specific letter
SELECT first_name, last_name
FROM store.customers
WHERE first_name LIKE 'A%';          -- starts with A (case-sensitive)


-- ILIKE: find gmail customers regardless of email case in raw data
SELECT first_name, email
FROM store.customers
WHERE email ILIKE '%@gmail.com';


-- NOT LIKE: exclude specific domains
SELECT first_name, email
FROM store.customers
WHERE email NOT ILIKE '%@gmail.com'
  AND email NOT ILIKE '%@yahoo.com';


-- _ wildcard: find 5-character first names
SELECT first_name
FROM store.customers
WHERE first_name LIKE '_____';       -- exactly 5 chars


-- POSIX regex ~: email must contain @ and end with .com or .in
SELECT first_name, email
FROM store.customers
WHERE email ~ '@.+\.(com|in)$';


-- POSIX regex ~*: find names starting with a vowel (case-insensitive)
SELECT first_name
FROM store.customers
WHERE first_name ~* '^[aeiou]';


-- !~ : find phone numbers with non-digit characters (data quality)
SELECT first_name, phone
FROM store.customers
WHERE phone !~ '^[0-9]+$';          -- contains non-digits


-- SKU starts with 'ELE' using LIKE vs LEFT() — same result
SELECT product_name, sku
FROM store.products
WHERE sku LIKE 'ELE%';

SELECT product_name, sku
FROM store.products
WHERE LEFT(sku, 3) = 'ELE';


-- =============================================================
-- SECTION 10 — NULL Handling in Strings
-- =============================================================

-- NULL propagates through || and most string functions.
-- COALESCE returns the first non-NULL value.
-- NULLIF(a, b) returns NULL if a = b, otherwise returns a.
-- Use CONCAT / CONCAT_WS to avoid NULL propagation naturally.

-- || NULL propagation demo
SELECT
    'Alice' || NULL             AS pipe_null,          -- NULL
    COALESCE('Alice' || NULL, 'fallback') AS safe;     -- 'fallback'


-- COALESCE: nickname with fallback to first_name
SELECT
    first_name,
    nickname,
    COALESCE(nickname, first_name)   AS display_name
FROM store.customers;


-- NULLIF: convert empty string middle_name to NULL first, then CONCAT_WS
SELECT
    first_name,
    middle_name,
    last_name,
    NULLIF(middle_name, '')                                     AS middle_clean,
    CONCAT_WS(' ', first_name, NULLIF(middle_name, ''), last_name) AS full_name
FROM store.employees;


-- NULLIF: convert placeholder values ('N/A', '-', '') to NULL
SELECT
    id,
    raw_notes,
    CASE
        WHEN TRIM(raw_notes) IN ('N/A', '-', '')  THEN NULL
        ELSE TRIM(raw_notes)
    END AS notes_clean
FROM store.raw_imports;


-- LENGTH of NULL vs empty string
SELECT
    LENGTH(NULL)     AS len_null,    -- NULL (not 0)
    LENGTH('')       AS len_empty,   -- 0
    LENGTH('hello')  AS len_hello;   -- 5


-- =============================================================
-- SECTION 11 — Common Mistakes
-- =============================================================

-- Mistake 1: single vs double quotes
-- Double quotes = identifier (column/table name), single quotes = string value
-- This would fail: SELECT "hello";  — tries to find column named hello
-- This is correct:
SELECT 'hello' AS greeting;


-- Mistake 2: LIKE is case-sensitive — ALICE won't match 'alice'
-- WRONG approach (will miss 'ALICE.COOPER@GMAIL.COM' in raw data):
SELECT COUNT(*) AS wrong_count
FROM store.raw_imports
WHERE raw_email LIKE '%@gmail.com';   -- misses UPPERCASE

-- RIGHT approach — normalise first:
SELECT COUNT(*) AS right_count
FROM store.raw_imports
WHERE LOWER(TRIM(raw_email)) LIKE '%@gmail.com';


-- Mistake 3: POSITION returns 0 (not NULL) when not found
-- Safe to use in WHERE without IS NULL check
SELECT first_name, email, POSITION('@' IN email) AS at_pos
FROM store.customers;
-- Eva returns 0 (missing @), not NULL


-- Mistake 4: SPLIT_PART returns '' (not NULL) for missing parts
SELECT
    SPLIT_PART('alice@example.com', '@', 3)              AS missing_part,    -- ''
    NULLIF(SPLIT_PART('alice@example.com', '@', 3), '')  AS missing_as_null; -- NULL


-- Mistake 5: || NULL = NULL — use CONCAT or COALESCE
SELECT
    first_name || ' ' || last_name                           AS with_pipe,    -- fine here
    first_name || ' ' || nickname || ' ' || last_name        AS nullable,     -- NULL when nickname is NULL
    CONCAT(first_name, ' ', nickname, ' ', last_name)        AS concat_safe,  -- skips NULL
    CONCAT_WS(' ', first_name, nickname, last_name)          AS ws_safe       -- skips NULL
FROM store.customers;


-- =============================================================
-- SECTION 12 — Combined: Data Cleaning Pipeline
-- =============================================================

-- Real-world pattern: clean raw_imports before loading into customers table
-- Steps: trim → lowercase → remove non-digits → validate → label

SELECT
    id,
    -- Name: trim and title-case
    INITCAP(TRIM(raw_name))                                     AS clean_name,

    -- Email: trim, lowercase, validate presence of @ and .
    LOWER(TRIM(raw_email))                                      AS clean_email,
    CASE
        WHEN POSITION('@' IN LOWER(TRIM(raw_email))) > 0
         AND POSITION('.' IN LOWER(TRIM(raw_email))) > 0
        THEN 'Valid'
        ELSE 'Invalid'
    END                                                         AS email_status,

    -- Phone: strip non-digits, validate length = 10
    REGEXP_REPLACE(raw_phone, '[^0-9]', '', 'g')               AS digits_only,
    CASE
        WHEN LENGTH(REGEXP_REPLACE(raw_phone, '[^0-9]', '', 'g')) = 10
        THEN 'Valid'
        ELSE 'Invalid'
    END                                                         AS phone_status,

    -- Notes: collapse spaces, convert placeholders to NULL
    CASE
        WHEN TRIM(raw_notes) IN ('N/A', '-', '')
        THEN NULL
        ELSE REGEXP_REPLACE(TRIM(raw_notes), '\s+', ' ', 'g')
    END                                                         AS clean_notes

FROM store.raw_imports
ORDER BY id;


-- =============================================================
-- SECTION 13 — Combined: STRING_AGG + SPLIT_PART + FORMAT
-- =============================================================

-- Build a product catalogue summary per category
-- Shows: category, product count, price range, all tags as one string

SELECT
    category,
    COUNT(*)                                                            AS product_count,
    FORMAT('₹%s – ₹%s', MIN(price)::TEXT, MAX(price)::TEXT)            AS price_range,
    ROUND(AVG(price), 2)                                                AS avg_price,
    STRING_AGG(product_name, ' | ' ORDER BY price DESC)                 AS products,
    STRING_AGG(DISTINCT tag, ', ' ORDER BY tag)                         AS all_tags
FROM store.products,
     LATERAL UNNEST(STRING_TO_ARRAY(tags, ',')) AS t(tag)
GROUP BY category
ORDER BY product_count DESC;


-- Customer report: full name + email username + order summary
SELECT
    CONCAT_WS(' ', c.first_name, c.last_name)                         AS full_name,
    SPLIT_PART(c.email, '@', 1)                                        AS username,
    SPLIT_PART(c.email, '@', 2)                                        AS domain,
    COUNT(o.order_id)                                                   AS order_count,
    COALESCE(SUM(o.amount), 0)                                         AS total_spent,
    COALESCE(STRING_AGG(o.order_id::TEXT, ', ' ORDER BY o.order_id), 'None') AS order_ids
FROM store.customers   c
LEFT JOIN store.orders o ON c.customer_id = o.customer_id
WHERE POSITION('@' IN c.email) > 0    -- valid emails only
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_spent DESC;
