-- Index Order Matters: Challenge #4
-- Run after setup.sql.

-- Remove any prior experiment indexes so each observation is isolated.
DROP INDEX IF EXISTS idx_orders_status_customer;
DROP INDEX IF EXISTS idx_orders_customer_status;
ANALYZE orders;

-- 1. Baseline: no composite index.
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';

-- 2. Incorrect order: status is the leading column.
CREATE INDEX idx_orders_status_customer
    ON orders (status, customer_id);
ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';

-- 3. Correct order: customer_id is the leading column for this access pattern.
DROP INDEX idx_orders_status_customer;
CREATE INDEX idx_orders_customer_status
    ON orders (customer_id, status);
ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';

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
