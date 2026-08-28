-- =============================================================
-- Problem 4 Solution — Apples & Oranges  (LeetCode #1581)
-- *** Instructor use only ***
-- =============================================================
-- Run problem4.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — Conditional aggregation with SUM + CASE (one scan)
-- =============================================================
-- One pass over the table. CASE separates apples from oranges.
-- SUM the apples column minus SUM the oranges column per date.

SELECT
    sale_date,
    SUM(CASE WHEN fruit = 'apples'  THEN sold_num ELSE 0 END) -
    SUM(CASE WHEN fruit = 'oranges' THEN sold_num ELSE 0 END) AS diff
FROM sales
GROUP BY sale_date
ORDER BY sale_date;


-- =============================================================
-- APPROACH 2 — Self JOIN (pivot by joining the table to itself)
-- =============================================================
-- Join the table to itself: one side filters apples, other oranges.
-- Then subtract directly on the joined row.

SELECT
    a.sale_date,
    a.sold_num - o.sold_num AS diff
FROM sales a
JOIN sales o
    ON a.sale_date = o.sale_date
   AND a.fruit = 'apples'
   AND o.fruit = 'oranges'
ORDER BY a.sale_date;


-- =============================================================
-- APPROACH 3 — Signed SUM trick (no CASE, no JOIN)
-- =============================================================
-- Assign +1 to apples and -1 to oranges, then multiply by sold_num.
-- SUM per date gives apples_total - oranges_total in one expression.

SELECT
    sale_date,
    SUM(sold_num * CASE WHEN fruit = 'apples' THEN 1 ELSE -1 END) AS diff
FROM sales
GROUP BY sale_date
ORDER BY sale_date;

-- Note:
--   Approach 1 is the most readable and interview-standard.
--   Approach 2 (self JOIN) works but scans the table twice.
--   Approach 3 is the most concise — one SUM, no separate CASE per fruit.
