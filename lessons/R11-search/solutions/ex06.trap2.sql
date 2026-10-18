-- sai: hàm bọc đúng, cột sinh đúng nhưng quên index (truy vấn đúng nhưng không dùng được index)
CREATE FUNCTION public.f_unaccent(text) RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$ SELECT public.unaccent('public.unaccent', $1) $$;
ALTER TABLE products ADD COLUMN search_vec tsvector GENERATED ALWAYS AS (to_tsvector('simple', public.f_unaccent(name))) STORED;
