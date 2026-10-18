\! { psql -X -q -U postgres -d lab -c "BEGIN; SELECT id FROM p08.jobs WHERE id = 1 FOR UPDATE; SELECT pg_sleep(4); COMMIT;" ; exit 0; } > /dev/null 2>&1 < /dev/null &
\! sleep 1
\set ON_ERROR_STOP off
:ans
;
ROLLBACK;
\set ON_ERROR_STOP on
SELECT pg_temp.ck(pg_temp.val($$SELECT state FROM p08.jobs WHERE id = 2$$) = 'taken', 'worker lấy được job 2 (job 1 đang bị khóa)');
SELECT pg_temp.ck(pg_temp.val($$SELECT state FROM p08.jobs WHERE id = 1$$) = 'new', 'job 1 vẫn thuộc về B (chưa bị lấy)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p08.jobs WHERE state = 'taken'$$) = '1', 'đúng 1 job được lấy');
\! sleep 4
