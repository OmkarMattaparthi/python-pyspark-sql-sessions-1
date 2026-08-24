# Day 6 Problems — SQL String Functions

> Use the `store` schema created in `day6_practice.sql`.
> Tables: `customers`, `products`, `orders`, `employees`, `raw_imports`.

---

## Section 1: LENGTH, UPPER, LOWER, INITCAP

**Q1.** Write a query that returns all customers with their `name`, the length of their name as `name_length`, and their `email` in all lowercase as `email_lower`. Sort by `name_length` descending.

---

**Q2.** From the `products` table, return `product_name` in UPPER case, `category` in LOWER case, and `brand` in title case (INITCAP). Show original values alongside.

---

**Q3.** Find all customers whose name, when converted to lowercase, starts with the letter `'a'`. Use `LOWER()` in the WHERE clause (not ILIKE).

---

**Q4.** Write a query that checks for data quality: find all customers where `LOWER(email)` does not end with `'.com'` or `'.in'`. Show `name` and `email`.

---

## Section 2: TRIM, LTRIM, RTRIM, LPAD, RPAD

**Q5.** The `raw_imports` table has messy data with leading/trailing spaces in `raw_name` and `raw_email`. Write a query that returns cleaned versions of both columns using `TRIM`. Show original and cleaned side by side.

---

**Q6.** Write a query that generates a zero-padded employee code for each employee: format `emp_id` as a 6-digit string with leading zeros. Show `emp_id`, `name`, and `emp_code`. Example: emp_id 3 → `'000003'`. Use `LPAD`.

---

**Q7.** From the `raw_imports` table, clean the `raw_phone` column: remove any leading zeros using `LTRIM`, then use `LPAD` to re-pad it back to exactly 10 digits. Show `raw_phone` and `cleaned_phone`.

---

## Section 3: POSITION, STRPOS, SUBSTRING, LEFT, RIGHT

**Q8.** From the `customers` table, extract the **username** (part before `@`) and the **domain** (part after `@`) from the `email` column. Use `POSITION` and `SUBSTRING` (or `SPLIT_PART`). Show `name`, `username`, `domain`.

---

**Q9.** From the `products` table, the `sku` column has the format `CAT-BRAND-NNNN` (e.g. `'ELE-SONY-0042'`). Extract:
- `category_code` — first 3 characters
- `brand_code` — characters 5–8
- `item_number` — last 4 characters

Show `sku`, `category_code`, `brand_code`, `item_number`. Use `LEFT`, `RIGHT`, and `SUBSTRING`.

---

**Q10.** Find all customers whose email contains more than one `@` sign (malformed data). Use `STRPOS` or `LENGTH` + `REPLACE` to count occurrences. Show `name` and `email`.

---

**Q11.** Write a query that returns the **last word** in each product's `product_name`. Assume the last word starts after the last space. Use `REVERSE` + `STRPOS` + `REVERSE` trick, or `SPLIT_PART` with a negative index approach. Show `product_name` and `last_word`.

---

## Section 4: REPLACE, TRANSLATE, REGEXP_REPLACE

**Q12.** The `raw_imports` table has phone numbers stored with hyphens: `'98-765-43210'`. Write a query that removes all hyphens using `REPLACE`. Show `raw_phone` and `clean_phone`.

---

**Q13.** Write a query that masks the middle part of each customer's email for display: replace characters between the first character and `@` with `***`. Example: `'alice@gmail.com'` → `'a***@gmail.com'`. Use `CONCAT`, `LEFT`, `POSITION`, and `SUBSTRING`.

---

**Q14.** The `raw_imports` table has a `raw_notes` column with multiple consecutive spaces. Use `REGEXP_REPLACE` to collapse all sequences of whitespace into a single space. Show `raw_notes` and `cleaned_notes`.

---

**Q15.** Use `TRANSLATE` to create a simple "slug" from product names: replace spaces with `-`, remove all punctuation (`'`, `"`, `!`, `?`), and convert to lowercase. Show `product_name` and `slug`. (Use `TRANSLATE` for removal, `REPLACE` + `LOWER` for the rest.)

---

## Section 5: SPLIT_PART, STRING_TO_ARRAY, UNNEST

**Q16.** Each product's `tags` column stores comma-separated tags like `'wireless,bluetooth,audio'`. Use `SPLIT_PART` to extract:
- `tag_1` — first tag
- `tag_2` — second tag
- `tag_3` — third tag

Show `product_name` and the three tag columns.

---

**Q17.** Write a query that uses `STRING_TO_ARRAY` and `UNNEST` to split each product's `tags` into separate rows. Show `product_name` and `tag` — one row per tag per product.

---

**Q18.** Using `SPLIT_PART`, extract the year, month, and day parts from the `order_ref` column in `orders` (format: `'ORD-2024-08-15-001'`). Show `order_ref`, `ref_year`, `ref_month`, `ref_day`.

---

## Section 6: CONCAT, CONCAT_WS, FORMAT, STRING_AGG

**Q19.** Write a query that builds a formatted address string for each customer:
`'<name> | <city>, <country>'`. Use `CONCAT_WS` where the separator handles NULLs gracefully. If `country` is NULL, show just the city.

---

**Q20.** Use `FORMAT` to generate a product label string for each product:
`'[CAT] ProductName — ₹Price'`
Example: `'[Electronics] Laptop Pro — ₹80000.00'`
Show `product_id` and `label`.

---

**Q21.** Write a query that uses `STRING_AGG` to list all product names per category as a comma-separated string. Show `category` and `product_list`. Sort product names alphabetically within each group.

---

**Q22.** Write a query that uses `STRING_AGG` to show each customer and a list of their order IDs separated by `' | '`. Include customers with no orders (show `'No orders'` using COALESCE). Show `name` and `order_list`.

---

## Section 7: Pattern Matching — LIKE, ILIKE, ~

**Q23.** Find all customers whose email matches the pattern for Gmail addresses (ends with `@gmail.com`). Use `ILIKE`. Show `name` and `email`.

---

**Q24.** Find all products whose `product_name` contains a number. Use the POSIX regex operator `~`. Pattern: `'[0-9]'`.

---

**Q25.** Write a query using `LIKE` to find all products whose `sku` starts with `'ELE'` (Electronics category). Then rewrite it using `LEFT(sku, 3) = 'ELE'`. Both should return the same result.

---

**Q26.** Find all customers whose phone number does NOT match the pattern of exactly 10 digits. Use `!~` with the regex `'^[0-9]{10}$'`. Show `name` and `phone` — these are data quality issues.

---

## Section 8: NULL Handling in Strings

**Q27.** The `employees` table has a `middle_name` column that is sometimes NULL and sometimes an empty string `''`. Write a query that returns a clean `full_name` combining `first_name`, `middle_name`, and `last_name` — skipping blank middle names. Use `CONCAT_WS` and `NULLIF`.

---

**Q28.** Write a query that shows each customer's `nickname` — if `nickname` is NULL, show their `first_name`; if `first_name` is also NULL, show `'Unknown'`. Use `COALESCE`.

---

**Q29.** In the `raw_imports` table, `raw_notes` sometimes contains `'N/A'`, `'-'`, or `''` as placeholder values. Write a query that converts all of these to `NULL`. Use `NULLIF` and `CASE`.

---

## Section 9: Combined Problems

**Q30.** Write a query that returns a **data quality report** on the `raw_imports` table. For each row show:
- `raw_name` (trimmed)
- `raw_email` (trimmed, lowercased)
- `email_valid` — `'Yes'` if email contains `@` and `.`, `'No'` otherwise
- `phone_valid` — `'Yes'` if phone (after removing hyphens) is exactly 10 digits, `'No'` otherwise
Use `POSITION`, `REPLACE`, `LENGTH`, and `CASE`.

---

**Q31.** Write a query that generates an **invoice reference** for each order in the format:
`'INV-<YYYY>-<zero-padded order_id 5 digits>-<CUSTOMER_INITIALS>'`
Example: `'INV-2024-00001-AC'` for Alice Cooper's order in 2024.
Customer initials = first letter of first_name + first letter of last_name, both uppercase.
Use `FORMAT`, `LPAD`, `LEFT`, `UPPER`, and date functions.

---

## Section 10: NULL Behavior and Mistakes

**Q32.** This query is supposed to build a full name but returns NULL for some employees. Explain why and fix it:
```sql
SELECT first_name || ' ' || middle_name || ' ' || last_name AS full_name
FROM store.employees;
```

---

**Q33.** This query should find all emails not from gmail. Explain what's wrong and fix it:
```sql
SELECT name, email
FROM store.customers
WHERE email LIKE '%@GMAIL.COM';
```

---

**Q34.** This query tries to find phone numbers without the digit `0` but returns unexpected results. Explain the issue:
```sql
SELECT name, phone
FROM store.customers
WHERE REPLACE(phone, '0', '') = phone;
```

---

## Bonus Challenges

**B1.** Write a query that ranks products by the number of vowels in their `product_name`. Count vowels using `LENGTH` and `REPLACE` (remove each vowel and subtract lengths). Show `product_name`, `vowel_count`. Sort descending.

---

**B2.** Write a query that parses the `tags` column (comma-separated) and returns, per category, the **most common tag** across all products in that category. Use `UNNEST`, `STRING_TO_ARRAY`, `GROUP BY`, and `COUNT`.

---

**B3.** Build a customer summary string for a notification system. For each customer generate:
```
Dear <INITCAP name>,
  Your account tier is <tier>.
  You have placed <order_count> orders totalling ₹<total_spent>.
  Member since: <signup_date formatted as 'DD Mon YYYY'>.
```
Return as a single text column `notification`. Use `FORMAT`, `TO_CHAR`, `CONCAT_WS`, `STRING_AGG`, and aggregate functions.
