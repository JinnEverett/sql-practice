CREATE INDEX ON users (lower(email) text_pattern_ops);
