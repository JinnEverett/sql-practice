\! { PGAPPNAME=p08_long psql -X -q -U postgres -d lab -c "BEGIN; SELECT count(*) FROM p08.big; SELECT pg_sleep(7); COMMIT;" ; exit 0; } > /dev/null 2>&1 < /dev/null &
\! sleep 1
\! { sh -c 'sleep 0.5; s=$(date +%s%N); psql -X -q -U postgres -d lab -c "SELECT count(*) FROM p08.big" > /dev/null 2>&1; e=$(date +%s%N); echo $(( (e-s)/1000000 )) > /tmp/p08_c.ms' ; exit 0; } > /dev/null 2>&1 < /dev/null &
\set ON_ERROR_STOP off
\o /dev/null
:ans
;
\o
\set ON_ERROR_STOP on
\! sleep 2
\set cms `cat /tmp/p08_c.ms`
SELECT pg_temp.ck(:'ans' ILIKE '%alter table%', 'bài làm thật sự chạy ALTER TABLE');
SELECT pg_temp.ck(:'cms'::int < 3000, 'người dùng SELECT bị chặn ' || :'cms' || ' ms (< 3 000; không timeout thì ≈ 6 000)');
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'p08_long' \g /dev/null
\! sleep 1
