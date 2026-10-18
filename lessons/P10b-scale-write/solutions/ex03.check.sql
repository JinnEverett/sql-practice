SELECT txid_snapshot_xmax(txid_current_snapshot())::bigint AS x0 \gset
\set ON_ERROR_STOP off
\o /dev/null
:ans
;
\o
\set ON_ERROR_STOP on
SELECT txid_snapshot_xmax(txid_current_snapshot())::bigint - :x0 AS used \gset
SELECT pg_temp.ck(pg_temp.same('SELECT id, v, pad FROM p10b.dst', 'SELECT id, v, pad FROM p10b.src') AND pg_temp.val('SELECT count(*) FROM p10b.dst') = '5000', 'dst có đủ 5 000 dòng giống src');
SELECT pg_temp.ck(:used <= 50, 'tiêu ' || :used || ' xid (≤ 50; từng dòng một là ≥ 5 000)');
