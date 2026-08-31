-- =============================================================
-- Problem 7 Medium Solution — Conditional Aggregation Pivot
-- *** Instructor use only ***
-- =============================================================
-- Run problem7_medium.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — COUNT(CASE WHEN) per priority column (most universal)
-- =============================================================
-- GROUP BY agent + category creates one row per agent-category pair.
-- Each COUNT(CASE WHEN ...) counts tickets of that priority in the group.

SELECT
    agent,
    category,
    COUNT(CASE WHEN priority = 'High'   THEN 1 END) AS high,
    COUNT(CASE WHEN priority = 'Medium' THEN 1 END) AS medium,
    COUNT(CASE WHEN priority = 'Low'    THEN 1 END) AS low
FROM support_tickets
GROUP BY agent, category
ORDER BY agent, category;


-- =============================================================
-- APPROACH 2 — SUM(CASE WHEN) with ELSE 0 (no NULLs in columns)
-- =============================================================
-- SUM with ELSE 0 ensures the column shows 0 instead of NULL
-- when no rows match the condition — same result here since
-- every combination has at least one ticket.

SELECT
    agent,
    category,
    SUM(CASE WHEN priority = 'High'   THEN 1 ELSE 0 END) AS high,
    SUM(CASE WHEN priority = 'Medium' THEN 1 ELSE 0 END) AS medium,
    SUM(CASE WHEN priority = 'Low'    THEN 1 ELSE 0 END) AS low
FROM support_tickets
GROUP BY agent, category
ORDER BY agent, category;


-- =============================================================
-- APPROACH 3 — FILTER clause (PostgreSQL-specific)
-- =============================================================

SELECT
    agent,
    category,
    COUNT(*) FILTER (WHERE priority = 'High')   AS high,
    COUNT(*) FILTER (WHERE priority = 'Medium') AS medium,
    COUNT(*) FILTER (WHERE priority = 'Low')    AS low
FROM support_tickets
GROUP BY agent, category
ORDER BY agent, category;

-- Note:
--   Approach 1 (COUNT + CASE) — COUNT ignores NULLs so no ELSE needed.
--   Approach 2 (SUM + CASE + ELSE 0) — explicit about returning 0 for missing combos.
--   Approach 3 (FILTER) — cleanest PostgreSQL syntax; not available in MySQL/SQL Server.
--   Key difference from easy problem: GROUP BY now has TWO columns (agent + category)
--   to create the agent × category breakdown instead of just per-agent totals.
