CREATE INDEX orders_open_idx ON orders (created_at) WHERE status IN ('pending', 'paid');
