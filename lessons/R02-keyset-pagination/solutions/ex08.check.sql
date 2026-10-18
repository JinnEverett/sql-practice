BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
:ddl
ANALYZE orders;
SELECT $q$SELECT id, created_at, total_amount FROM orders WHERE user_id = 200 AND (created_at, id) < ('2026-01-01 00:00+00', 900000) ORDER BY created_at DESC, id DESC LIMIT 20$q$ AS ref \gset
SELECT pg_temp.plan(:'q') AS p \gset
SELECT pg_temp.ck(pg_temp.same(:'q', :'ref'), 'kết quả đúng (20 dòng như tham chiếu)');
SELECT pg_temp.ck(pg_temp.rows_out(:'p'::jsonb) = 20, 'trả về đúng 20 dòng');
SELECT pg_temp.ck(pg_temp.uses_index(:'p'::jsonb), 'plan dùng index');
SELECT pg_temp.ck(NOT pg_temp.has_node(:'p'::jsonb, 'Sort'), 'không có bước Sort (index đã cho đúng thứ tự)');
SELECT pg_temp.ck(NOT pg_temp.has_node(:'p'::jsonb, 'Seq Scan'), 'không Seq Scan orders');
SELECT pg_temp.ck(pg_temp.buffers(:'p'::jsonb) < 300, 'đọc dưới 300 buffer (thực tế ' || pg_temp.buffers(:'p'::jsonb) || ')');
ROLLBACK;
