BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'q') AS p;
SELECT pg_temp.ck(pg_temp.val(:'q') = '1001', 'trả 1001 (nghĩa là "hơn 1000 kết quả")');
SELECT pg_temp.ck(pg_temp.buffers(p) < 1000, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 1000)') FROM p;
ROLLBACK;
