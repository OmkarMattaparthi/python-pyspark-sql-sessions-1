-- =============================================================
-- Problem 1 Hard Solution — Top 3 per Group + Running Total within top
-- *** Instructor use only ***
-- =============================================================


-- =============================================================
-- APPROACH 1 — RANK filter + SUM window on filtered set (CTE chain)
-- =============================================================
-- Step 1: rank all reps per region using RANK (handles ties).
-- Step 2: filter rank <= 3.
-- Step 3: compute running total within the filtered top-3 set per region,
--         ordered by amount DESC (so the running total accumulates top-down).

WITH ranked AS (
    SELECT
        region,
        rep_name,
        amount,
        RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS rank
    FROM sales
),
top3 AS (
    SELECT * FROM ranked WHERE rank <= 3
)
SELECT
    region,
    rank,
    rep_name,
    amount,
    SUM(amount) OVER (
        PARTITION BY region
        ORDER BY amount DESC, rep_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS region_running_total
FROM top3
ORDER BY region, rank, rep_name;


-- =============================================================
-- APPROACH 2 — Single CTE with both RANK and running total
-- =============================================================
-- Compute RANK and the running total in one CTE, filter in outer query.
-- The running total is computed over ALL rows first, then filtering
-- removes the non-top-3 rows — the running totals are pre-computed correctly.

WITH all_ranked AS (
    SELECT
        region,
        rep_name,
        amount,
        RANK() OVER (PARTITION BY region ORDER BY amount DESC)      AS rank,
        SUM(amount) OVER (
            PARTITION BY region
            ORDER BY amount DESC, rep_name
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                            AS region_running_total
    FROM sales
)
SELECT region, rank, rep_name, amount, region_running_total
FROM all_ranked
WHERE rank <= 3
ORDER BY region, rank, rep_name;

-- Note:
--   rep_name is added as a tiebreaker in ORDER BY inside SUM OVER to make
--   the running total deterministic when two reps have the same amount.
--   RANK() handles ties correctly — both get rank 2, next rank is 4 (skipped).
