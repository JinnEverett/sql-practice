\! for i in $(seq 1 100); do echo "INSERT INTO p10b.t4 VALUES ($((10000+i)), clock_timestamp()::text); SELECT pg_sleep(0.1);"; done > /tmp/p10b_w4.sql
\! { psql -X -q -U postgres -d lab -f /tmp/p10b_w4.sql ; exit 0; } > /dev/null 2>&1 < /dev/null &
\! sleep 1
\set ON_ERROR_STOP off
\o /dev/null
:ans
;
\o
\set ON_ERROR_STOP on
\! sleep 10
SELECT pg_temp.ck((SELECT count(*) FROM pg_index WHERE indrelid = 'p10b.t4'::regclass AND NOT indisprimary AND indisvalid) = 1, 'có đúng 1 index mới và indisvalid');
CREATE TEMP TABLE gaps AS SELECT max(extract(epoch FROM (pad::timestamptz - prev))) AS g FROM (SELECT pad, lag(pad::timestamptz) OVER (ORDER BY id) AS prev FROM p10b.t4 WHERE id > 10000) s;
SELECT pg_temp.ck((SELECT count(*) FROM p10b.t4 WHERE id > 10000) >= 90, 'writer ghi được ' || (SELECT count(*) FROM p10b.t4 WHERE id > 10000) || '/100 dòng');
SELECT pg_temp.ck(g < 1.0, 'khoảng lặng lớn nhất của writer: ' || round(g::numeric, 2) || ' giây (< 1.0; CREATE INDEX thường chặn ≈ 5.7 giây)') FROM gaps;
