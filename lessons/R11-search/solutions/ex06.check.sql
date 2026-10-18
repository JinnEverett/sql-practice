BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT is_generated FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'search_vec'$$) = 'ALWAYS', 'products.search_vec là cột GENERATED ALWAYS');
SELECT pg_temp.ck(pg_temp.val($$SELECT public.f_unaccent('Ốp lưng Đà Nẵng')$$) = 'Op lung Da Nang', 'public.f_unaccent bỏ dấu đúng (kể cả Đ)');
SELECT pg_temp.ck(pg_temp.val($$SELECT provolatile::text FROM pg_proc WHERE oid = 'public.f_unaccent(text)'::regprocedure$$) = 'i', 'public.f_unaccent là IMMUTABLE');
SELECT $q$SELECT count(*) FROM products WHERE search_vec @@ plainto_tsquery('simple', public.f_unaccent('ao thun'))$q$ AS q1 \gset
SELECT $q$SELECT count(*) FROM products WHERE to_tsvector('simple', unaccent(name)) @@ plainto_tsquery('simple', unaccent('ao thun'))$q$ AS r1 \gset
SELECT pg_temp.ck(pg_temp.val(:'q1')::int > 0 AND pg_temp.val(:'q1') = pg_temp.val(:'r1'), 'tìm "ao thun" (không dấu) ra đúng ' || pg_temp.val(:'r1') || ' sản phẩm Áo thun');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM products WHERE search_vec @@ plainto_tsquery('simple', public.f_unaccent('áo thun'))$$) = pg_temp.val(:'r1'), 'tìm "áo thun" (có dấu) ra cùng kết quả');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO products (category_id, sku, name, brand, price, stock, created_at) VALUES (9, 'ZZ-TEST-1', 'Áo thun Đặc Biệt', 'Zed', 1000, 1, now())$$), 'chèn sản phẩm mới');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM products WHERE search_vec @@ plainto_tsquery('simple', public.f_unaccent('dac biet'))$$) = '1', 'sản phẩm mới tìm được ngay bằng "dac biet" (cột sinh tự cập nhật)');
SET LOCAL enable_seqscan = off;
SELECT pg_temp.plan(:'q1') AS p \gset
SELECT pg_temp.ck(pg_temp.uses_index(:'p'::jsonb), 'truy vấn dùng được index trên search_vec');
ROLLBACK;
