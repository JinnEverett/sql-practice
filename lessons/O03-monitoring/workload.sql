-- O03 · tải giả lập (chạy được bằng tay: docker exec -i sql-practice-pg psql -U postgres -d lab -q < workload.sql)
-- Bộ chấm chạy cùng khối lệnh này. Sau khi chạy, xem pg_stat_statements / pg_stat_user_tables.
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
