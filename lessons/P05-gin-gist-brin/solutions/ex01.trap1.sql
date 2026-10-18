CREATE INDEX ON events (((properties->>'product_id')::int));
