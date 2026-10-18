BEGIN;
:ans
;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, status, total_amount FROM orders WHERE user_id = 4242$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 28, 'query trả 28 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.uses_index(p), 'plan dùng index') FROM p;
SELECT pg_temp.ck(NOT pg_temp.has_node(p, 'Seq Scan', 'orders'), 'không còn Seq Scan trên orders') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 100, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 100; trước đó 11 929)') FROM p;
ROLLBACK;
