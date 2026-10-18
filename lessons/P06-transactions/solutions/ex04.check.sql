\set ON_ERROR_STOP off
SELECT split_part(:'ans', E'-- >>> B\n', 1) AS a1, split_part(:'ans', E'-- >>> B\n', 2) AS a2 \gset
SELECT pg_temp.ck(:'a2' <> '', 'bài làm có dòng "-- >>> B" chia thành 2 đoạn');
SELECT :'a1' AS q \gexec
\! { psql -X -q -U postgres -d lab -c "UPDATE p06.acct SET balance = balance + 50 WHERE id = 1" ; exit 0; } > /dev/null 2>&1 < /dev/null &
\! sleep 1
SELECT :'a2' AS q \gexec
\! sleep 1.5
ROLLBACK;
\set ON_ERROR_STOP on
SELECT pg_temp.ck(pg_temp.val($$SELECT balance FROM p06.acct WHERE id = 1$$) = '180', 'balance cuối = ' || pg_temp.val($$SELECT balance FROM p06.acct WHERE id = 1$$) || ' (100 + 50 của B + 30 của A = 180, không mất cập nhật nào)');
