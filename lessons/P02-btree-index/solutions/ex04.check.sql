BEGIN;
:ans
;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT user_id, count(*) AS n, sum(total_amount) AS revenue FROM orders WHERE user_id BETWEEN 1000 AND 1999 GROUP BY user_id$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 1000, 'query trả 1 000 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.has_node(p, 'Index Only Scan', 'orders'), 'có Index Only Scan trên orders') FROM p;
SELECT pg_temp.ck(coalesce((jsonb_path_query_first(p, '$.**."Heap Fetches"') #>> '{}')::bigint, 999999) <= 100, 'Heap Fetches ' || coalesce(jsonb_path_query_first(p, '$.**."Heap Fetches"') #>> '{}', '?') || ' (≤ 100)') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 1000, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 1 000)') FROM p;
ROLLBACK;
