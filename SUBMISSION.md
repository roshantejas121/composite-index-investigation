# Submission Summary

## Implemented

- Created a reproducible PostgreSQL `orders` table with 500,000 rows.
- Added the baseline query and `EXPLAIN (ANALYZE, BUFFERS)` measurements.
- Tested the incorrect `(status, customer_id)` index.
- Tested the corrected `(customer_id, status)` index.
- Documented the left-most prefix rule, planner behavior, and read/write trade-offs.

## Review command

```bash
createdb index_order_lab
psql -d index_order_lab -f setup.sql
psql -d index_order_lab -f experiment.sql
```

The reviewer should compare the scan type, index conditions, buffers, rows removed by filtering, and execution time in each plan. Exact timings are intentionally not hard-coded because they depend on the PostgreSQL environment.
