CREATE INDEX ON users USING gist (email gist_trgm_ops);
