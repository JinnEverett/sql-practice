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
SELECT pg_temp.ck((SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name = 'ans_v' AND table_schema LIKE 'pg_temp%') = 'query,calls,total_ms,mean_ms', 'cột query, calls, total_ms, mean_ms');
SELECT pg_temp.ck((SELECT count(*) FROM ans_v) = 5, 'đúng 5 dòng');
SELECT pg_temp.ck((SELECT query FROM ans_v LIMIT 1) ILIKE '%AS a%', 'dòng đầu là pg_sleep(0.5) × 3 lần (tổng ~1500 ms lớn nhất)');
SELECT pg_temp.ck((SELECT total_ms >= 1400 FROM ans_v LIMIT 1), 'total_ms dòng đầu ≥ 1400');
SELECT pg_temp.ck(NOT EXISTS (SELECT 1 FROM ans_v WHERE query ILIKE '%pg_stat_statements%'), 'không có câu lệnh của chính pg_stat_statements');

SELECT pg_temp.ck((SELECT total_ms FROM ans_v LIMIT 1) = (SELECT max(total_ms) FROM ans_v), 'dòng đầu có total_ms lớn nhất');
