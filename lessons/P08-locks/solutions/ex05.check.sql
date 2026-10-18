\! { psql -X -q -U postgres -d lab -c "SELECT pg_advisory_lock(42); SELECT pg_sleep(4);" ; exit 0; } > /dev/null 2>&1 < /dev/null &
\! sleep 1
\set ON_ERROR_STOP off
\o /dev/null
:ans
;
\o
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p08.runs$$) = '0', 'lúc job trước còn chạy: job mới KHÔNG chạy (runs = ' || pg_temp.val($$SELECT count(*) FROM p08.runs$$) || ')');
\! sleep 4
\o /dev/null
:ans
;
\o
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p08.runs$$) = '1', 'khi khóa rảnh: job chạy (runs = ' || pg_temp.val($$SELECT count(*) FROM p08.runs$$) || ')');
