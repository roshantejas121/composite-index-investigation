-- Reproducible PostgreSQL setup for the composite-index experiment.
-- Run with: psql -v ON_ERROR_STOP=1 -d index_order_lab -f setup.sql
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id    BIGSERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'cancelled')),
    amount      NUMERIC(10, 2) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL
);

-- 500,000 deterministic rows: enough data for the planner to make a
-- meaningful choice without relying on random values or prior database state.
INSERT INTO orders (customer_id, status, amount, created_at)
SELECT
    1 + ((series_number - 1) % 1000)::int,
    (ARRAY['pending', 'processing', 'completed', 'cancelled'])[1 + ((series_number - 1) % 4)::int],
    round((10 + ((series_number * 37) % 990))::numeric, 2),
    TIMESTAMPTZ '2024-01-01 00:00:00+00' - ((series_number % 730) * interval '1 day')
FROM generate_series(1, 500000) AS generated(series_number);

ANALYZE orders;
