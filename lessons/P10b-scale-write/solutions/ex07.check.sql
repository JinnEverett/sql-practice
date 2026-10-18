\! for i in $(seq 1 100); do echo "INSERT INTO p10b.t7 VALUES ($((10000+i)), clock_timestamp()::text); SELECT pg_sleep(0.1);"; done > /tmp/p10b_w7.sql
\! { psql -X -q -U postgres -d lab -f /tmp/p10b_w7.sql ; exit 0; } > /dev/null 2>&1 < /dev/null &
\! sleep 1
\set ON_ERROR_STOP off
\o /dev/null
:ans
;
\o
\set ON_ERROR_STOP on
\! sleep 8
SELECT pg_temp.ck((SELECT convalidated FROM pg_constraint WHERE conrelid = 'p10b.t7'::regclass AND contype = 'c' LIMIT 1) IS TRUE, 'ràng buộc CHECK đã được VALIDATE');
CREATE TEMP TABLE gaps AS SELECT max(extract(epoch FROM (pad::timestamptz - prev))) AS g FROM (SELECT pad, lag(pad::timestamptz) OVER (ORDER BY id) AS prev FROM p10b.t7 WHERE id > 10000) s;
SELECT pg_temp.ck((SELECT count(*) FROM p10b.t7 WHERE id > 10000) >= 90, 'writer ghi được ' || (SELECT count(*) FROM p10b.t7 WHERE id > 10000) || '/100 dòng');
SELECT pg_temp.ck(g < 1.0, 'khoảng lặng lớn nhất của writer: ' || round(g::numeric, 2) || ' giây (< 1.0; ADD CONSTRAINT trần chặn ≈ 5.7 giây)') FROM gaps;
