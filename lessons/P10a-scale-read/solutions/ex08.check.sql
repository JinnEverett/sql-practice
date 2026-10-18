SET max_parallel_workers_per_gather = 0;
BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
SELECT nullif(btrim(:'ddl'), '') AS x \gexec
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'q') AS p;
SELECT pg_temp.ck(pg_temp.same(:'q', $ref$SELECT id, ts FROM p10.t_m WHERE gen < 5000 ORDER BY ts DESC LIMIT 20$ref$), 'kết quả giống query gốc (20 bản ghi)');
SELECT pg_temp.ck(pg_temp.buffers(p) < 3000, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 3 000; plan gốc ~13 400)') FROM p;
ROLLBACK;
