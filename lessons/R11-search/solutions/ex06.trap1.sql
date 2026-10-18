-- sai: dùng unaccent() trực tiếp trong cột sinh → lỗi 42P17 (không IMMUTABLE)
ALTER TABLE products ADD COLUMN search_vec tsvector GENERATED ALWAYS AS (to_tsvector('simple', unaccent(name))) STORED;
