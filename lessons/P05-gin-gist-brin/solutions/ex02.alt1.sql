CREATE INDEX ON events USING brin (created_at) WITH (pages_per_range = 16);
