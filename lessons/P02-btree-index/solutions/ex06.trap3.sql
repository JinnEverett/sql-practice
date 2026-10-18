CREATE INDEX ON orders (((created_at AT TIME ZONE 'UTC')::date));
