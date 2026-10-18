BEGIN;
:ans
;
CREATE FUNCTION pg_temp.has_leading_index(t regclass, c text) RETURNS boolean LANGUAGE sql AS $$
  SELECT EXISTS (SELECT 1 FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
                 WHERE i.indrelid = t AND a.attname = c)
$$;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r01.tags (name) VALUES ('hot'), ('new')$$), 'thêm tag (id tự sinh)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.tags (name) VALUES ('HOT')$$, '23505'), 'tag trùng khác hoa/thường bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.tags (name) VALUES (' x ')$$, '23514'), 'tag có khoảng trắng đầu/cuối bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r01.product_tags SELECT 1, id FROM r01.tags$$), 'gắn 2 tag cho sản phẩm 1');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r01.product_tags SELECT 2, id FROM r01.tags WHERE name = 'hot'$$), 'gắn tag cho sản phẩm 2');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.product_tags SELECT 1, id FROM r01.tags WHERE name = 'hot'$$, '23505'), 'gắn trùng cặp (sản phẩm, tag) bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.product_tags VALUES (99, 1)$$, '23503'), 'gắn tag cho sản phẩm không tồn tại bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$DELETE FROM r01.tags WHERE name = 'hot'$$, '23503'), 'không xóa được tag đang được dùng');
SELECT pg_temp.ck(pg_temp.ok($$DELETE FROM r01.catalog WHERE id = 1$$), 'xóa sản phẩm 1');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r01.product_tags WHERE product_id = 1$$) = '0', 'dòng nối của sản phẩm 1 tự mất (CASCADE)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r01.tags$$) = '2', 'tag vẫn còn nguyên');
SELECT pg_temp.ck(pg_temp.has_leading_index('r01.product_tags', 'tag_id'), 'có index với tag_id đứng đầu (tìm sản phẩm theo tag)');
ROLLBACK;
