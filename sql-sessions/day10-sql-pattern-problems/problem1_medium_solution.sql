-- =============================================================
-- Problem 1 Medium Solution — Top N per Group
-- *** Instructor use only ***
-- =============================================================
-- Run problem1_medium.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — RANK in CTE, filter rank <= 2 (standard)
-- =============================================================
-- RANK gives tied rows the same rank number.
-- Both tied rows at rank 2 pass the filter — unlike ROW_NUMBER.

WITH ranked AS (
    SELECT
        region,
        rep_name,
        amount,
        RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS rank
    FROM sales
)
SELECT region, rank, rep_name, amount
FROM ranked
WHERE rank <= 2
ORDER BY region, rank;


-- =============================================================
-- APPROACH 2 — DENSE_RANK (no gaps after ties)
-- =============================================================
-- Same as RANK but if two people tie at rank 1, next is rank 2.
-- For top-2 with ties DENSE_RANK <= 2 may return more than 2 rows.
-- Use when you want "top 2 distinct values" not "top 2 positions".

WITH ranked AS (
    SELECT
        region,
        rep_name,
        amount,
        DENSE_RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS rank
    FROM sales
)
SELECT region, rank, rep_name, amount
FROM ranked
WHERE rank <= 2
ORDER BY region, rank;


-- =============================================================
-- APPROACH 3 — Subquery: filter rows where fewer than 2 reps beat them
-- =============================================================
-- A rep is in the top 2 if at most 1 other rep in the same region
-- has a strictly higher amount. No window function needed.

SELECT
    s1.region,
    s1.rep_name,
    s1.amount
FROM sales s1
WHERE (
    SELECT COUNT(*)
    FROM sales s2
    WHERE s2.region = s1.region AND s2.amount > s1.amount
) < 2
ORDER BY s1.region, s1.amount DESC;

-- Note:
--   Approach 1 (RANK) is the interview standard for top-N with ties.
--   Approach 2 (DENSE_RANK) useful when "top 2 values" matters, not "top 2 positions".
--   Approach 3 (correlated subquery) is dialect-agnostic but slow on large tables.
--   Key difference from easy: ROW_NUMBER would miss ties; RANK includes them.
