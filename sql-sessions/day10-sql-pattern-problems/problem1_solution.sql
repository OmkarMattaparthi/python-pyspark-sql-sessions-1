-- =============================================================
-- Problem 1 Solution — Top N per Group
-- *** Instructor use only ***
-- =============================================================
-- Run problem1.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — ROW_NUMBER in CTE, filter rn = 1 (most common)
-- =============================================================
-- Assign row number per region ordered by amount DESC.
-- Row 1 = highest earner. Filter rn = 1 in outer query.

WITH ranked AS (
    SELECT
        region,
        rep_name,
        amount,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY amount DESC) AS rn
    FROM sales
)
SELECT region, rep_name, amount
FROM ranked
WHERE rn = 1
ORDER BY region;


-- =============================================================
-- APPROACH 2 — Subquery with MAX join
-- =============================================================
-- Get the max amount per region, then join back to find the rep.
-- Works in all SQL dialects (no window functions needed).

SELECT s.region, s.rep_name, s.amount
FROM sales s
JOIN (
    SELECT region, MAX(amount) AS max_amount
    FROM sales
    GROUP BY region
) m ON s.region = m.region AND s.amount = m.max_amount
ORDER BY s.region;


-- =============================================================
-- APPROACH 3 — DISTINCT ON (PostgreSQL-specific, very concise)
-- =============================================================
-- DISTINCT ON (region) keeps the first row per region.
-- ORDER BY region, amount DESC ensures the first row = highest amount.

SELECT DISTINCT ON (region) region, rep_name, amount
FROM sales
ORDER BY region, amount DESC;

-- Note:
--   Approach 1 (ROW_NUMBER CTE) is the interview standard — works everywhere.
--   Approach 2 (MAX join) is dialect-agnostic but verbose with ties.
--   Approach 3 (DISTINCT ON) is PostgreSQL-only but the most concise.
