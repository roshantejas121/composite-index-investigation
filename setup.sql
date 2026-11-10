-- Reproducible PostgreSQL setup for the composite-index experiment.
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id    BIGSERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'cancelled')),
    amount      NUMERIC(10, 2) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL
);

-- 500,000 rows: enough data for the planner to make a meaningful choice.
INSERT INTO orders (customer_id, status, amount, created_at)
SELECT
    1 + floor(random() * 1000)::int,
    (ARRAY['pending', 'processing', 'completed', 'cancelled'])[1 + floor(random() * 4)::int],
    round((10 + random() * 990)::numeric, 2),
    now() - (random() * interval '730 days')
FROM generate_series(1, 500000);

ANALYZE orders;
