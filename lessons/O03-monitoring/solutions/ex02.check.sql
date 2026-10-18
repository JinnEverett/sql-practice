-- tải giả lập (giống workload.sql)
SELECT pg_stat_statements_reset();
SELECT pg_sleep(0.5) AS a;
SELECT pg_sleep(0.5) AS a;
SELECT pg_sleep(0.5) AS a;
SELECT pg_sleep(0.8), 1 AS b;
SELECT 'SELECT v FROM o03.small WHERE id = 5' FROM generate_series(1, 500) \gexec
SELECT count(*) FROM o03.big WHERE grp = 7;
SELECT count(*) FROM o03.big WHERE grp = 7;
SELECT pg_stat_force_next_flush();
SELECT 1;
SELECT format('CREATE TEMP VIEW ans_v AS %s', pg_temp.clean(:'ans')) \gexec
SELECT pg_temp.ck((SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name = 'ans_v' AND table_schema LIKE 'pg_temp%') = 'query,calls,blks_total,blks_per_call', 'cột query, calls, blks_total, blks_per_call');
SELECT pg_temp.ck((SELECT count(*) FROM ans_v) = 3, 'đúng 3 dòng');
SELECT pg_temp.ck((SELECT query FROM ans_v LIMIT 1) ILIKE '%o03.big%', 'dòng đầu là truy vấn quét o03.big (≈ 4000 block mỗi lần)');
SELECT pg_temp.ck((SELECT blks_per_call > 1000 FROM ans_v LIMIT 1), 'blks_per_call dòng đầu > 1000');
SELECT pg_temp.ck(EXISTS (SELECT 1 FROM ans_v WHERE query ILIKE '%o03.small%' AND blks_per_call < 10), 'truy vấn o03.small: gọi 500 lần nhưng < 10 block mỗi lần');
SELECT pg_temp.ck(NOT EXISTS (SELECT 1 FROM ans_v WHERE query ILIKE '%pg_stat_statements%'), 'không có câu lệnh của chính pg_stat_statements');
