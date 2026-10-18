BEGIN;
:ans
;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, total_amount FROM orders WHERE (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = DATE '2025-11-11'$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 6516, 'query trả 6 516 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.uses_index(p), 'plan dùng index') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 300, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 300)') FROM p;
ROLLBACK;
