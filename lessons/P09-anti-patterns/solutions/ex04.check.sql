BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
SELECT nullif(btrim(:'ddl'), '') AS x \gexec
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'q') AS p;
SELECT pg_temp.ck(pg_temp.same(:'q', $ref$SELECT id, created_at, total_amount FROM orders ORDER BY created_at DESC, id DESC OFFSET 900000 LIMIT 20$ref$), 'kết quả giống query gốc');
SELECT pg_temp.ck(NOT pg_temp.has_node(p, 'Sort'), 'không có node Sort') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 100, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM p;
ROLLBACK;
