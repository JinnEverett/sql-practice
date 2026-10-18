BEGIN;
:ans
;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, user_id, created_at FROM orders WHERE status IN ('pending','paid') ORDER BY created_at LIMIT 50$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 50, 'query trả 50 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.uses_index(p) AND NOT pg_temp.has_node(p, 'Seq Scan'), 'dùng index, không Seq Scan') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 150, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 150)') FROM p;
SELECT pg_temp.ck((SELECT coalesce(sum(pg_relation_size(indexrelid)), 0) FROM pg_index WHERE indrelid = 'public.orders'::regclass AND indexrelid <> 'public.orders_pkey'::regclass) BETWEEN 1 AND 5 * 1024 * 1024,
                  'index mới tổng ' || (SELECT round(coalesce(sum(pg_relation_size(indexrelid)), 0) / 1048576.0, 2) FROM pg_index WHERE indrelid = 'public.orders'::regclass AND indexrelid <> 'public.orders_pkey'::regclass) || ' MB (≤ 5 MB)');
ROLLBACK;
