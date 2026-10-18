BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
SELECT nullif(btrim(:'ddl'), '') AS x \gexec
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'q') AS p;
SELECT pg_temp.ck(pg_temp.same(:'q', $ref$SELECT o.id FROM orders o JOIN users u ON u.id = o.user_id WHERE o.id = 123456 OR u.email = 'nhung.le500@outlook.com'$ref$), 'kết quả giống query gốc');
SELECT pg_temp.ck(NOT pg_temp.has_node(p, 'Seq Scan', 'orders'), 'không còn Seq Scan trên orders') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 400, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 400)') FROM p;
ROLLBACK;
