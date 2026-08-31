-- =============================================================
-- Problem 7 Medium — Conditional Aggregation (Pivot)
-- Pattern: COUNT(CASE WHEN) to pivot multiple categories into columns
-- =============================================================
-- Question:
--   For each agent, show how many High, Medium, and Low priority
--   tickets exist per category — all pivoted into one row.
--   Return: agent, category, high, medium, low.
--   Order by agent, category.
-- =============================================================

DROP TABLE IF EXISTS support_tickets;

CREATE TABLE support_tickets (
    ticket_id  SERIAL PRIMARY KEY,
    agent      VARCHAR(50),
    category   VARCHAR(50),
    status     VARCHAR(20),
    priority   VARCHAR(10),
    created_at DATE
);

INSERT INTO support_tickets (agent, category, status, priority, created_at) VALUES
    ('Alice', 'Billing',   'Resolved', 'High',   '2024-01-05'),
    ('Alice', 'Technical', 'Open',     'Low',    '2024-01-06'),
    ('Alice', 'Billing',   'Resolved', 'Medium', '2024-01-07'),
    ('Alice', 'Technical', 'Resolved', 'High',   '2024-01-08'),
    ('Bob',   'Billing',   'Open',     'High',   '2024-01-05'),
    ('Bob',   'Technical', 'Resolved', 'Medium', '2024-01-06'),
    ('Bob',   'Billing',   'Resolved', 'Low',    '2024-01-07'),
    ('Bob',   'Technical', 'Open',     'High',   '2024-01-08'),
    ('Carol', 'Billing',   'Resolved', 'Low',    '2024-01-05'),
    ('Carol', 'Technical', 'Resolved', 'Medium', '2024-01-06'),
    ('Carol', 'Billing',   'Open',     'High',   '2024-01-07'),
    ('Carol', 'Technical', 'Resolved', 'High',   '2024-01-08');

-- Expected output:
--
--   agent | category  | high | medium | low
--   ------+-----------+------+--------+----
--   Alice | Billing   |    1 |      1 |   0
--   Alice | Technical |    1 |      0 |   1
--   Bob   | Billing   |    1 |      0 |   1
--   Bob   | Technical |    1 |      1 |   0
--   Carol | Billing   |    1 |      0 |   1
--   Carol | Technical |    1 |      1 |   0

-- YOUR ANSWER:
