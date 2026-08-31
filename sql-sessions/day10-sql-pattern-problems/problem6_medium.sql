-- =============================================================
-- Problem 6 Medium — Previous and Next Record Comparison
-- Pattern: LAG + CASE to compute MoM change and trend label
-- =============================================================
-- Question:
--   For each department and month, show the revenue, the previous
--   month's revenue, the absolute change (revenue - prev_revenue),
--   and a trend label: 'Increase', 'Decrease', or 'No Change'.
--   First month per dept shows NULL for prev_revenue and change.
--   Order by dept, month.
-- =============================================================

DROP TABLE IF EXISTS monthly_revenue;

CREATE TABLE monthly_revenue (
    rev_id   SERIAL PRIMARY KEY,
    dept     VARCHAR(50),
    month    DATE,
    revenue  NUMERIC(12,2)
);

INSERT INTO monthly_revenue (dept, month, revenue) VALUES
    ('Engineering', '2024-01-01', 120000.00),
    ('Engineering', '2024-02-01', 135000.00),
    ('Engineering', '2024-03-01', 128000.00),
    ('Engineering', '2024-04-01', 142000.00),
    ('Sales',       '2024-01-01',  95000.00),
    ('Sales',       '2024-02-01',  88000.00),
    ('Sales',       '2024-03-01', 102000.00),
    ('Sales',       '2024-04-01',  97000.00);

-- Expected output:
--
--   dept        | month      | revenue    | prev_revenue | change    | trend
--   ------------+------------+------------+--------------+-----------+---------
--   Engineering | 2024-01-01 | 120000.00  | NULL         | NULL      | NULL
--   Engineering | 2024-02-01 | 135000.00  | 120000.00    | 15000.00  | Increase
--   Engineering | 2024-03-01 | 128000.00  | 135000.00    | -7000.00  | Decrease
--   Engineering | 2024-04-01 | 142000.00  | 128000.00    | 14000.00  | Increase
--   Sales       | 2024-01-01 |  95000.00  | NULL         | NULL      | NULL
--   Sales       | 2024-02-01 |  88000.00  |  95000.00    | -7000.00  | Decrease
--   Sales       | 2024-03-01 | 102000.00  |  88000.00    | 14000.00  | Increase
--   Sales       | 2024-04-01 |  97000.00  | 102000.00    | -5000.00  | Decrease

-- YOUR ANSWER:
