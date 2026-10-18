\set ON_ERROR_STOP off
SELECT split_part(:'ans', E'-- >>> B\n', 1) AS a1, split_part(:'ans', E'-- >>> B\n', 2) AS a2 \gset
SELECT pg_temp.ck(:'a2' <> '', 'bài làm có dòng "-- >>> B" chia thành 2 đoạn');
\pset tuples_only on
\pset format unaligned
\o /tmp/p08_ex03_b.sql
SELECT replace(replace(:'a1', ':from', '2'), ':to', '1') || E'\nSELECT pg_sleep(1);\n' || replace(replace(:'a2', ':from', '2'), ':to', '1');
\o
\pset tuples_only off
\pset format aligned
SELECT replace(replace(:'a1', ':from', '1'), ':to', '2') AS q \gexec
\! { psql -X -q -U postgres -d lab -f /tmp/p08_ex03_b.sql ; exit 0; } > /tmp/p08_ex03_b.out 2>&1 < /dev/null &
\! sleep 2
SELECT replace(replace(:'a2', ':from', '1'), ':to', '2') AS q \gexec
\! sleep 4
ROLLBACK;
\set ON_ERROR_STOP on
\set bout `grep -c 'deadlock detected' /tmp/p08_ex03_b.out || true`
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p08.xfer_log$$) = '2', 'cả hai lần chuyển tiền đều commit (' || pg_temp.val($$SELECT count(*) FROM p08.xfer_log$$) || '/2): không bị hủy vì deadlock');
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(balance::text, ',' ORDER BY id) FROM p08.acct$$) = '100,100', 'số dư cuối 100,100 (10 đi 10 về)');
SELECT pg_temp.ck(:'bout'::int = 0, 'session B không gặp "deadlock detected"');
