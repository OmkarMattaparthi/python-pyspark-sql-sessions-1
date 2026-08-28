-- =============================================================
-- Problem 4 — Apples & Oranges  (LeetCode #1581)
-- DATA ENGINEER SQL INTERVIEW CHALLENGE
-- =============================================================
-- Question:
--   Report the difference between the number of apples and
--   oranges sold each day (apples - oranges).
--   Return the result ordered by sale_date.
-- =============================================================

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    sale_date  DATE,
    fruit      VARCHAR(10),
    sold_num   INT
);

INSERT INTO sales (sale_date, fruit, sold_num) VALUES
    ('2020-05-01', 'apples',  10),
    ('2020-05-01', 'oranges',  8),
    ('2020-05-02', 'apples',  15),
    ('2020-05-02', 'oranges', 15);

-- Expected output:
--
--   sale_date  | diff
--   -----------+------
--   2020-05-01 |    2    (10 - 8)
--   2020-05-02 |    0    (15 - 15)

-- YOUR ANSWER:
