-- =============================================================
-- Problem 1 Solution — Count Salary Categories  (LeetCode #1907)
-- *** Instructor use only ***
-- =============================================================
-- Run problem1.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — UNION ALL with conditional COUNT (most common)
-- =============================================================
-- Each SELECT targets one category using a WHERE filter.
-- UNION ALL stitches the three rows together.
-- Guarantees all 3 categories appear even when count = 0
-- because we always SELECT a literal string — never filter the row out.

SELECT 'Low Salary'     AS category, COUNT(*) AS accounts_count FROM accounts WHERE income < 20000
UNION ALL
SELECT 'Average Salary' AS category, COUNT(*) AS accounts_count FROM accounts WHERE income BETWEEN 20000 AND 50000
UNION ALL
SELECT 'High Salary'    AS category, COUNT(*) AS accounts_count FROM accounts WHERE income > 50000;


-- =============================================================
-- APPROACH 2 — CASE inside COUNT with a category spine CTE
-- =============================================================
-- A VALUES list defines the three category labels (the "spine").
-- A single pass over accounts classifies each row with CASE.
-- LEFT JOIN spine → category ensures 0-count categories appear.
-- Good when you want to avoid scanning the table 3 times.

WITH category_spine (category) AS (
    VALUES ('Low Salary'), ('Average Salary'), ('High Salary')
),
classified AS (
    SELECT
        CASE
            WHEN income < 20000                    THEN 'Low Salary'
            WHEN income BETWEEN 20000 AND 50000    THEN 'Average Salary'
            ELSE                                        'High Salary'
        END AS category
    FROM accounts
)
SELECT
    s.category,
    COUNT(c.category) AS accounts_count
FROM category_spine s
LEFT JOIN classified c ON c.category = s.category
GROUP BY s.category
ORDER BY s.category;


-- =============================================================
-- APPROACH 3 — SUM + CASE (conditional aggregation, one scan)
-- =============================================================
-- One SELECT, one scan. Each SUM counts rows matching its condition.
-- CASE returns 1 when the condition is true, 0 otherwise → SUM = count.
-- No JOIN, no UNION — simplest single-query form.

SELECT
    SUM(CASE WHEN income < 20000                 THEN 1 ELSE 0 END) AS "Low Salary",
    SUM(CASE WHEN income BETWEEN 20000 AND 50000 THEN 1 ELSE 0 END) AS "Average Salary",
    SUM(CASE WHEN income > 50000                 THEN 1 ELSE 0 END) AS "High Salary"
FROM accounts;

-- Note: Approach 3 returns one row with 3 columns (wide format).
-- Approaches 1 & 2 return 3 rows with 2 columns (long format = expected output).
-- Use Approach 1 or 2 for the interview answer; Approach 3 is a quick sanity check.
