BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
:ddl
ANALYZE users;
SELECT $q$SELECT id, full_name FROM users WHERE full_name ILIKE '%nguyễn văn hải%' ORDER BY id$q$ AS ref \gset
SELECT pg_temp.plan(:'q') AS p \gset
SELECT pg_temp.ck(pg_temp.same(:'q', :'ref'), 'kết quả đúng (59 người)');
SELECT pg_temp.ck(pg_temp.uses_index(:'p'::jsonb), 'plan dùng index');
SELECT pg_temp.ck(NOT pg_temp.has_node(:'p'::jsonb, 'Seq Scan', 'users'), 'không Seq Scan bảng users');
SELECT pg_temp.ck(pg_temp.buffers(:'p'::jsonb) < 600, 'đọc dưới 600 buffer (thực tế ' || pg_temp.buffers(:'p'::jsonb) || '; Seq Scan khoảng 1 500)');
ROLLBACK;
