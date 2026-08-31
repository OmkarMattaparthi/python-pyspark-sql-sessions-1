-- =============================================================
-- Problem 6 Hard — Previous and Next Record Comparison
-- Pattern: LAG + LEAD + best/worst month + full MoM trend summary
-- =============================================================
-- Question:
--   For each department produce ONE summary row with:
--     - best_month        : month with highest revenue
--     - best_revenue      : that month's revenue
--     - worst_month       : month with lowest revenue
--     - worst_revenue     : that month's revenue
--     - avg_mom_change    : average month-over-month change across all months
--                           (exclude the first month which has no previous)
--     - trend_summary     : e.g. '2 Increase, 1 Decrease, 0 No Change'
--                           (count of each trend across all non-first months)
--   Order by dept.
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
--   dept        | best_month | best_revenue | worst_month | worst_revenue | avg_mom_change | trend_summary
--   ------------+------------+--------------+-------------+---------------+----------------+------------------------------
--   Engineering | 2024-04-01 |    142000.00 | 2024-01-01  |     120000.00 |       7333.33  | 2 Increase, 1 Decrease, 0 No Change
--   Sales       | 2024-03-01 |    102000.00 | 2024-02-01  |      88000.00 |        666.67  | 1 Increase, 2 Decrease, 0 No Change
--
-- Note:
--   Engineering MoM changes: +15000, -7000, +14000 → avg = (15000-7000+14000)/3 = 7333.33
--   Sales MoM changes: -7000, +14000, -5000        → avg = (-7000+14000-5000)/3 = 666.67

-- YOUR ANSWER:
