BEGIN;
SELECT split_part(:'ans', '-- query', 1) AS ddl, split_part(:'ans', '-- query', 2) AS q \gset
SELECT nullif(btrim(:'ddl'), '') AS x \gexec
SELECT (pg_temp.plan(:'q', false)::text LIKE '%SubPlan%') AS bad \gset
\if :bad
SELECT pg_temp.ck(false, 'plan còn SubPlan/Materialize (kiểu NOT IN): không chạy thử vì mất hàng giờ');
\else
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'q') AS p;
SELECT pg_temp.ck(pg_temp.val(:'q') = pg_temp.val($ref$SELECT count(*) FROM users u WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)$ref$), 'kết quả đúng: ' || pg_temp.val(:'q') || ' khách chưa từng đặt đơn');
SELECT pg_temp.ck(pg_temp.buffers(p) < 15000, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 15000)') FROM p;
\endif
ROLLBACK;
