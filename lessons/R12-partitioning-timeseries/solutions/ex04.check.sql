BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT partstrat::text FROM pg_partitioned_table WHERE partrelid = 'r12.tenant_logs'::regclass$$) = 'h', 'chiến lược HASH');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_inherits WHERE inhparent = 'r12.tenant_logs'::regclass$$) = '4', 'có 4 partition');
INSERT INTO r12.tenant_logs SELECT 1 + i % 200, i, 'm' FROM generate_series(1, 4000) i;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r12.tenant_logs$$) = '4000', 'chèn 4000 dòng của 200 tenant không lỗi (hash phủ kín mọi giá trị)');
SELECT pg_temp.ck(pg_temp.val($$SELECT min(c)::numeric / max(c) > 0.5 FROM (SELECT count(*) c FROM r12.tenant_logs GROUP BY tableoid) t$$) = 'true', 'các partition khá đều nhau (nhỏ nhất > 50% lớn nhất; thực tế ' || pg_temp.val($$SELECT string_agg(c::text, '/' ORDER BY c) FROM (SELECT count(*) c FROM r12.tenant_logs GROUP BY tableoid) t$$) || ')');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(DISTINCT tableoid) FROM r12.tenant_logs WHERE tenant_id = 7$$) = '1', 'mọi dòng của một tenant nằm trong đúng 1 partition');
SELECT pg_temp.plan($q$SELECT count(*) FROM r12.tenant_logs WHERE tenant_id = 7$q$, false) AS p \gset
SELECT count(DISTINCT v) AS n_scanned FROM jsonb_path_query(:'p'::jsonb, '$.** ? (@."Relation Name" like_regex "^tenant_logs_")."Relation Name"') v \gset
SELECT pg_temp.ck(:n_scanned = 1, 'truy vấn theo tenant_id = 7 chỉ quét 1 partition (quét ' || :n_scanned || ')');
ROLLBACK;
