BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
SELECT nullif(btrim(:'ddl'), '') AS x \gexec
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'q') AS p;
SELECT pg_temp.ck(pg_temp.same(:'q', $ref$SELECT DISTINCT ON (user_id) user_id, id AS order_id, created_at FROM orders WHERE user_id <= 50 ORDER BY user_id, created_at DESC, id DESC$ref$), 'kết quả giống query gốc');
SELECT pg_temp.ck(pg_temp.buffers(p) < 1500, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 1500)') FROM p;
ROLLBACK;
