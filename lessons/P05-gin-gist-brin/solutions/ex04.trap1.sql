CREATE INDEX ON products USING gin (to_tsvector('english', name));
