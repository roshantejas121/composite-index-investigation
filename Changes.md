# Changes

## Investigation

The target query is:

```sql
SELECT *
FROM orders
WHERE customer_id = 451
  AND status = 'completed';
```

The query has equality predicates on both columns, but the order of a B-tree composite index still determines how PostgreSQL can enter the index and constrain the scan.

## Baseline

With no composite index, PostgreSQL has no suitable access path and normally uses a sequential scan. As the table grows, this requires checking every row against both predicates.

## Incorrect index

The first experiment creates:

```sql
CREATE INDEX idx_orders_status_customer
    ON orders (status, customer_id);
```

This index is sorted first by `status`, then by `customer_id`. It is useful for queries that begin with `status`, for example:

```sql
WHERE status = 'completed';
```

It is not the best structure for the target access pattern because the query is intended to locate the customer first and then check that customer's status. Depending on data distribution and cost estimates, PostgreSQL may use this index only partially, scan a large portion of the `status = 'completed'` range, or choose a sequential scan. An index existing in the database does not guarantee that the planner will use it.

## Corrected index

The corrected index is:

```sql
CREATE INDEX idx_orders_customer_status
    ON orders (customer_id, status);
```

Now entries are grouped first by `customer_id` and then by `status`. PostgreSQL can navigate directly to the entries for customer 451 and use the second key to find only the completed orders for that customer. This produces a much narrower candidate range than scanning all completed orders or the entire table.

## Left-most prefix rule

For a B-tree index on `(customer_id, status)`, the useful prefixes are:

```sql
WHERE customer_id = 451;
WHERE customer_id = 451 AND status = 'completed';
```

A query that filters only on `status` skips the left-most column. PostgreSQL generally cannot use the index to jump directly to a small range for that predicate, although it can sometimes use the index for a less efficient full or broad index scan. The rule is therefore a design guide, not an absolute promise that an index will never be touched.

## Validation

`experiment.sql` runs:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

for the baseline, incorrect index, and corrected index. The relevant evidence is the scan type, `Index Cond`, rows removed by filtering, buffer reads, and total execution time. Exact output varies with PostgreSQL version, statistics, cache state, hardware, and data distribution, so the measurements must be collected in the environment where the assignment is evaluated.

The optional diagnostic section temporarily sets `enable_seqscan = off` to confirm that the corrected index is a valid access path. This is not a performance fix and should not be left enabled in production.

## Engineering trade-off

Composite indexes improve reads but add storage and write overhead. Before adding one, inspect the real workload with `EXPLAIN (ANALYZE, BUFFERS)`, confirm the column order matches common predicates, and remove redundant indexes when possible.
