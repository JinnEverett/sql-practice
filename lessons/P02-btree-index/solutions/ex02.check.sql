BEGIN;
:ans
;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, created_at FROM orders WHERE user_id = 4242 ORDER BY created_at DESC LIMIT 5$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 5, 'query trả 5 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.uses_index(p), 'plan dùng index') FROM p;
SELECT pg_temp.ck(NOT pg_temp.has_node(p, 'Sort'), 'không có node Sort') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 30, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 30)') FROM p;
ROLLBACK;
