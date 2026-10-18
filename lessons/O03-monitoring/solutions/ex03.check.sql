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
SELECT pg_temp.ck((SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name = 'ans_v' AND table_schema LIKE 'pg_temp%') = 'relname,seq_scan,idx_scan,seq_tup_read,size', 'cột relname, seq_scan, idx_scan, seq_tup_read, size');
SELECT pg_temp.ck((SELECT count(*) FROM ans_v) = 1 AND (SELECT relname FROM ans_v LIMIT 1) = 'big', 'chỉ bảng big (lớn, quét tuần tự nhiều hơn index)');
SELECT pg_temp.ck((SELECT idx_scan FROM ans_v LIMIT 1) = 0, 'idx_scan của big = 0');
SELECT pg_temp.ck((SELECT seq_tup_read >= 600000 FROM ans_v LIMIT 1), 'seq_tup_read ≥ 600000 (2 lần quét 300000 dòng)');
