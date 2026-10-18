BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
SELECT nullif(btrim(:'ddl'), '') AS x \gexec
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'q') AS p;
SELECT pg_temp.ck(pg_temp.same(:'q', $ref$SELECT id, total_amount FROM orders WHERE user_id::text = '4242'$ref$), 'kết quả giống query gốc');
SELECT pg_temp.ck(pg_temp.uses_index(p), 'plan dùng index') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 100, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM p;
ROLLBACK;
