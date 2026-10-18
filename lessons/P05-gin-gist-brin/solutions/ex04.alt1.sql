CREATE INDEX products_name_fts ON products USING gist (to_tsvector('simple', name));
