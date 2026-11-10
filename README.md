# Composite Index Investigation

This repository demonstrates why the order of columns in a PostgreSQL composite index affects whether a query can use the index efficiently.

## Scenario

The query filters the `orders` table by both `customer_id` and `status`:

```sql
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';
```

The experiment compares an index whose leading column is `status` with a corrected index whose leading column is `customer_id`.

## Run the experiment

Requirements: PostgreSQL 13+ and a database where you can create tables and indexes.

```bash
createdb index_order_lab
psql -d index_order_lab -f setup.sql
psql -d index_order_lab -f experiment.sql
```

`setup.sql` creates a reproducible `orders` table and loads 500,000 synthetic rows. `experiment.sql` runs `EXPLAIN (ANALYZE, BUFFERS)` for the baseline, incorrect-index, and corrected-index cases.

For stable demonstrations, the script disables sequential scans only for the final corrected-index observation. In a production investigation, do not disable planner methods; use it only to confirm that the corrected access path is viable. The normal planner decision is the authoritative result.

## Files

- `setup.sql` — schema and reproducible sample data.
- `experiment.sql` — query-plan experiment and index definitions.
- `Changes.md` — explanation of the findings and the left-most prefix rule.

## Expected observation

The incorrect index is `INDEX(status, customer_id)`. It may help when a query starts with `status`, but it does not match the leading equality predicate for the target access pattern. The corrected index is `INDEX(customer_id, status)`, which lets PostgreSQL navigate directly to a customer and then narrow those rows by status.

Exact timings and whether PostgreSQL chooses an index scan depend on PostgreSQL version, statistics, hardware, cache state, and table size. Always verify with `EXPLAIN ANALYZE` in the target environment rather than copying timings from another machine.
