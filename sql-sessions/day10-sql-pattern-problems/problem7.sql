-- =============================================================
-- Problem 7 — Conditional Aggregation
-- Pattern: SUM/COUNT with CASE WHEN to pivot counts into columns
-- =============================================================
-- Question:
--   For each agent show: total tickets, how many are Resolved,
--   and how many are Open — all in one row.
--   Order by agent.
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
--   agent | total | resolved | open
--   ------+-------+----------+-----
--   Alice |     4 |        3 |    1
--   Bob   |     4 |        2 |    2
--   Carol |     4 |        3 |    1

-- YOUR ANSWER:
