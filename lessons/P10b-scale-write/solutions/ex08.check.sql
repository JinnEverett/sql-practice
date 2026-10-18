SELECT txid_snapshot_xmax(txid_current_snapshot())::bigint AS x0 \gset
\set ON_ERROR_STOP off
\o /dev/null
:ans
;
\o
\set ON_ERROR_STOP on
SELECT txid_snapshot_xmax(txid_current_snapshot())::bigint - :x0 AS used \gset
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p10b.big WHERE amount_big IS DISTINCT FROM amount$$) = '0', 'mọi dòng đã backfill amount_big = amount');
SELECT pg_temp.ck(:used >= 6, 'chia thành nhiều transaction: dùng ' || :used || ' xid (≥ 6; một câu UPDATE là 2)');
SELECT pg_temp.ck(:used <= 2000, 'không commit từng dòng (' || :used || ' xid ≤ 2 000)');
