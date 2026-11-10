-- Index Order Matters: Challenge #4
-- Run after setup.sql with: psql -v ON_ERROR_STOP=1 -d index_order_lab -f experiment.sql
\set ON_ERROR_STOP on
\timing on

-- Remove any prior experiment indexes so each observation is isolated.
DROP INDEX IF EXISTS idx_orders_status_customer;
DROP INDEX IF EXISTS idx_orders_customer_status;
ANALYZE orders;

\echo '=== BASELINE: no composite index ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';

\echo '=== EXPERIMENT A: index(status, customer_id) ==='
CREATE INDEX idx_orders_status_customer
    ON orders (status, customer_id);
ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';

\echo '=== EXPERIMENT B: index(customer_id, status) ==='
DROP INDEX idx_orders_status_customer;
CREATE INDEX idx_orders_customer_status
    ON orders (customer_id, status);
ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';

\echo '=== DIAGNOSTIC: corrected index with sequential scans disabled ==='
-- Optional diagnostic only: prove the corrected index can serve the query.
-- Reset this setting after the check. Do not use this in production tuning.
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';
ROLLBACK;
