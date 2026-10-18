BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT valid_to::text FROM r05.price_history_bad WHERE product_id = 1 AND valid_from = '2026-01-01 00:00+00'$$) = '2026-02-15 00:00:00+00', 'sản phẩm 1: khoảng giá 100 được cắt về 2026-02-15');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r05.price_history_bad$$) = '7', 'không mất dòng nào');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r05.price_history_bad a JOIN r05.price_history_bad b ON a.product_id = b.product_id AND a.valid_from < b.valid_from AND b.valid_from < coalesce(a.valid_to, 'infinity')$$) = '0', 'không còn khoảng nào chồng nhau');
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(product_id || ':' || coalesce(valid_to::text, 'open'), ',' ORDER BY product_id, valid_from) FROM r05.price_history_bad WHERE product_id IN (2, 3)$$) = '2:2026-02-01 00:00:00+00,2:open,3:2026-03-01 00:00:00+00,3:open', 'dữ liệu hợp lệ của sản phẩm 2, 3 không bị đổi');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r05.price_history_bad VALUES (3, 33, '2026-02-15 00:00+00', '2026-03-15 00:00+00')$$, '23P01'), 'chèn khoảng chồng lên khoảng có sẵn bị chặn (23P01)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r05.price_history_bad VALUES (2, 70, '2026-03-01 00:00+00', NULL)$$, '23P01'), 'khoảng mở chồng lên khoảng đang hiệu lực bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r05.price_history_bad VALUES (3, 33, '2026-03-01 00:00+00', '2026-04-01 00:00+00')$$), 'lấp đúng khoảng trống [03-01, 04-01) của sản phẩm 3: được (liền kề không chồng)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r05.price_history_bad VALUES (4, 10, '2026-01-01 00:00+00', NULL)$$), 'sản phẩm khác không liên quan: được');
ROLLBACK;
