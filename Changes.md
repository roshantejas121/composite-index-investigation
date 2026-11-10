# Changes

## Scope

This submission makes the composite-index experiment directly reviewable from the pull request. The target query is:

```sql
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';
```

The experiment compares these two B-tree definitions:

```sql
-- Experiment A: leading column does not match the intended access path
CREATE INDEX idx_orders_status_customer
    ON orders (status, customer_id);

-- Experiment B: leading column matches the customer lookup
CREATE INDEX idx_orders_customer_status
    ON orders (customer_id, status);
```

## Reproducible setup

`setup.sql` drops and recreates `orders`, then inserts exactly 500,000 deterministic rows. Customer IDs, statuses, amounts, and timestamps are derived from `generate_series`, so a reviewer can rerun the experiment without depending on a prior database state or random data. The script also runs `ANALYZE` before any plan is collected.

Run from the repository root:

```bash
createdb index_order_lab
psql -v ON_ERROR_STOP=1 -d index_order_lab -f setup.sql
psql -v ON_ERROR_STOP=1 -d index_order_lab -f experiment.sql
```

## Experiment A: `(status, customer_id)`

The first key groups all rows by status. For the target query, PostgreSQL can enter the `status = 'completed'` range, but the customer predicate is not the leading access condition. The plan may therefore scan many completed rows and apply `customer_id = 451` as a filter, or choose a sequential scan when that is cheaper. The planner's choice depends on PostgreSQL version, statistics, cache state, and hardware.

## Experiment B: `(customer_id, status)`

The corrected index groups rows by customer first and status second. PostgreSQL can navigate to the narrow `customer_id = 451` range and then apply `status = 'completed'` inside that range. This matches the target query's selective access pattern and should produce fewer candidate rows than Experiment A.

## What to verify

`experiment.sql` prints a labeled `EXPLAIN (ANALYZE, BUFFERS)` plan for the baseline, Experiment A, and Experiment B. Compare:

- scan type (`Seq Scan`, `Index Scan`, or another access path);
- `Index Cond` versus filter predicates;
- rows removed by filtering;
- shared buffer hits/reads; and
- actual execution time in the local PostgreSQL environment.

The script also includes a transaction-scoped `enable_seqscan = off` diagnostic after Experiment B. That check only proves that the corrected index is a valid access path; it is not a production tuning recommendation. The normal planner decision remains the authoritative performance result.

## Left-most prefix rule and trade-off

For `(customer_id, status)`, the useful leading prefixes include `customer_id` alone and `customer_id` plus `status`. A predicate on `status` alone skips the left-most column and generally cannot jump directly to a small B-tree range. Composite indexes can improve reads but consume storage and add write and maintenance work, so the column order should follow the real workload and be validated with `EXPLAIN (ANALYZE, BUFFERS)`.
