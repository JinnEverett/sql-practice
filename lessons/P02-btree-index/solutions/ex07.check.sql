BEGIN;
:ans
;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, email FROM users WHERE email LIKE 'hung.pham88%'$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 2, 'query trả 2 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.uses_index(p), 'plan dùng index') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 30, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 30; Seq Scan là 1 526)') FROM p;
ROLLBACK;
