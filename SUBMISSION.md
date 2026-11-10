# Submission Summary

## Review links

- Repository: https://github.com/roshantejas121/composite-index-investigation
- Pull request: https://github.com/roshantejas121/composite-index-investigation/pull/2

## Implemented

- Created a reproducible PostgreSQL `orders` table with 500,000 rows.
- Added the baseline query and `EXPLAIN (ANALYZE, BUFFERS)` measurements.
- Tested the incorrect `(status, customer_id)` index.
- Tested the corrected `(customer_id, status)` index.
- Documented the left-most prefix rule, planner behavior, and read/write trade-offs.

The reproducible artifacts are committed at the repository root: [`Changes.md`](Changes.md), [`setup.sql`](setup.sql), and [`experiment.sql`](experiment.sql).

## Review command

```bash
createdb index_order_lab
psql -v ON_ERROR_STOP=1 -d index_order_lab -f setup.sql
psql -v ON_ERROR_STOP=1 -d index_order_lab -f experiment.sql
```

The reviewer should compare the scan type, index conditions, buffers, rows removed by filtering, and execution time in each plan. Exact timings are intentionally not hard-coded because they depend on the PostgreSQL environment.
