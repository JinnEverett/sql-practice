\! { PGAPPNAME=p07_report psql -X -q -U postgres -d lab -c "BEGIN ISOLATION LEVEL REPEATABLE READ; SELECT count(*) FROM p07.held; SELECT pg_sleep(20); COMMIT;" ; exit 0; } > /dev/null 2>&1 < /dev/null &
\! sleep 1
UPDATE p07.held SET n = n + 1;
\o /dev/null
VACUUM p07.held;
\o
SELECT pg_temp.ck((SELECT dead_tuple_count FROM pgstattuple('p07.held')) >= 10000, 'trước khi xử lý: VACUUM bị chặn, còn ' || (SELECT dead_tuple_count FROM pgstattuple('p07.held')) || ' dead tuple (≥ 10 000)');
\o /dev/null
:ans
;
\o
\! sleep 1
\o /dev/null
VACUUM p07.held;
\o
SELECT pg_temp.ck((SELECT dead_tuple_count FROM pgstattuple('p07.held')) = 0, 'sau khi xử lý: VACUUM dọn hết, dead = ' || (SELECT dead_tuple_count FROM pgstattuple('p07.held')));
-- dọn session B nếu bài làm chưa giết nó, để không ảnh hưởng bài khác
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'p07_report' \g /dev/null
\! sleep 1
