-- =============================================================
-- Problem 1 Hard — Top N per Group
-- Pattern: Top 3 per region WITH ties + running total within top reps
-- =============================================================
-- Question:
--   Find the top 3 sales reps by amount in each region (ties included).
--   For each qualifying rep, also show their cumulative running total
--   within their region (ordered by amount DESC).
--   Return: region, rank, rep_name, amount, region_running_total.
--   Order by region, rank.
-- =============================================================

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    sale_id    SERIAL PRIMARY KEY,
    rep_name   VARCHAR(50),
    region     VARCHAR(50),
    amount     NUMERIC(10,2),
    sale_date  DATE
);

INSERT INTO sales (rep_name, region, amount, sale_date) VALUES
    ('Alice', 'North', 9500.00,  '2024-01-10'),
    ('Bob',   'North', 8200.00,  '2024-01-15'),
    ('Carol', 'North', 8200.00,  '2024-01-20'),  -- tie with Bob at 8200
    ('Dave',  'North', 6100.00,  '2024-01-25'),
    ('Eve',   'South', 11200.00, '2024-01-11'),
    ('Frank', 'South', 9800.00,  '2024-01-16'),
    ('Grace', 'South', 8700.00,  '2024-01-21'),
    ('Hank',  'South', 7400.00,  '2024-01-26'),
    ('Ivy',   'East',  10500.00, '2024-01-12'),
    ('Jack',  'East',  9300.00,  '2024-01-17'),
    ('Karen', 'East',  8100.00,  '2024-01-22'),
    ('Leo',   'East',  8100.00,  '2024-01-23');  -- tie with Karen at 8100

-- Expected output:
--
--   region | rank | rep_name | amount   | region_running_total
--   -------+------+----------+----------+---------------------
--   East   |    1 | Ivy      | 10500.00 |             10500.00
--   East   |    2 | Jack     |  9300.00 |             19800.00
--   East   |    3 | Karen    |  8100.00 |             27900.00
--   East   |    3 | Leo      |  8100.00 |             36000.00
--   North  |    1 | Alice    |  9500.00 |              9500.00
--   North  |    2 | Bob      |  8200.00 |             17700.00
--   North  |    2 | Carol    |  8200.00 |             25900.00
--   South  |    1 | Eve      | 11200.00 |             11200.00
--   South  |    2 | Frank    |  9800.00 |             21000.00
--   South  |    3 | Grace    |  8700.00 |             29700.00
--
-- Note: Bob and Carol tie at rank 2 (North) → both included, rank 3 skipped.
--       Karen and Leo tie at rank 3 (East) → both included.

-- YOUR ANSWER:
