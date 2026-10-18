\set ON_ERROR_STOP off
SELECT split_part(:'ans', E'-- >>> B\n', 1) AS a1, split_part(:'ans', E'-- >>> B\n', 2) AS a2 \gset
SELECT pg_temp.ck(:'a2' <> '', 'bài làm có dòng "-- >>> B" chia thành 2 đoạn');
\pset tuples_only on
\pset format unaligned
\o /tmp/p06_ex06_b.sql
SELECT replace(:'a1', ':me', '2') || E'\nSELECT pg_sleep(1);\n' || replace(:'a2', ':me', '2');
\o
\pset tuples_only off
\pset format aligned
SELECT replace(:'a1', ':me', '1') AS q \gexec
\! (psql -X -q -U postgres -d lab -f /tmp/p06_ex06_b.sql > /tmp/p06_ex06_b.out 2>&1 < /dev/null &)
\! sleep 2
SELECT replace(:'a2', ':me', '1') AS q \gexec
\! sleep 2
ROLLBACK;
\set ON_ERROR_STOP on
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p06.doctor WHERE on_call$$)::int >= 1, 'luôn còn ít nhất 1 bác sĩ trực: ' || pg_temp.val($$SELECT count(*) FROM p06.doctor WHERE on_call$$) || ' người');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p06.doctor WHERE NOT on_call$$)::int >= 1, 'có ít nhất 1 giao dịch thành công (ai đó đã nghỉ trực)');
