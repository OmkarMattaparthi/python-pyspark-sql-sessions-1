-- =============================================================
-- Problem 7 Solution — Conditional Aggregation
-- *** Instructor use only ***
-- =============================================================
-- Run problem7.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — SUM(CASE WHEN) — most universal
-- =============================================================
-- CASE returns 1 when the condition matches, 0 otherwise.
-- SUM adds them up → count of matching rows per agent.

SELECT
    agent,
    COUNT(*)                                                          AS total,
    SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END)             AS resolved,
    SUM(CASE WHEN status = 'Open'     THEN 1 ELSE 0 END)             AS open
FROM support_tickets
GROUP BY agent
ORDER BY agent;


-- =============================================================
-- APPROACH 2 — COUNT(CASE WHEN) — slightly more concise
-- =============================================================
-- CASE returns 1 on match, NULL otherwise.
-- COUNT ignores NULLs → counts only matching rows.

SELECT
    agent,
    COUNT(*)                                                          AS total,
    COUNT(CASE WHEN status = 'Resolved' THEN 1 END)                  AS resolved,
    COUNT(CASE WHEN status = 'Open'     THEN 1 END)                  AS open
FROM support_tickets
GROUP BY agent
ORDER BY agent;


-- =============================================================
-- APPROACH 3 — FILTER clause (PostgreSQL-specific, cleanest)
-- =============================================================
-- FILTER (WHERE ...) is PostgreSQL's cleaner syntax for conditional counts.
-- Equivalent to COUNT(CASE WHEN ...) but reads more naturally.

SELECT
    agent,
    COUNT(*)                                        AS total,
    COUNT(*) FILTER (WHERE status = 'Resolved')     AS resolved,
    COUNT(*) FILTER (WHERE status = 'Open')         AS open
FROM support_tickets
GROUP BY agent
ORDER BY agent;

-- Note:
--   Approach 1 (SUM + CASE) works in ALL SQL dialects — use in interviews.
--   Approach 2 (COUNT + CASE) is slightly shorter and equally portable.
--   Approach 3 (FILTER) is PostgreSQL-only but the cleanest to read.
--   All three return identical results.
