\set ON_ERROR_STOP off
SELECT split_part(:'ans', E'-- >>> B\n', 1) AS a1, split_part(:'ans', E'-- >>> B\n', 2) AS a2 \gset
SELECT pg_temp.ck(:'a2' <> '', 'bài làm có dòng "-- >>> B" chia thành 2 đoạn');
SELECT :'a1' AS q \gexec
\! (psql -X -q -U postgres -d lab -c "INSERT INTO p06.ticket VALUES (4, 'open')" > /dev/null 2>&1 < /dev/null &)
\! sleep 1
SELECT :'a2' AS q \gexec
\! sleep 1
ROLLBACK;
\set ON_ERROR_STOP on
SELECT pg_temp.ck((SELECT count(*) FROM p06.reads) = 2, 'đã ghi đúng 2 lần đếm (' || (SELECT count(*) FROM p06.reads) || ')');
SELECT pg_temp.ck((SELECT count(DISTINCT val) FROM p06.reads) = 1, 'hai lần đếm cùng giá trị: ' || coalesce((SELECT string_agg(step || '=' || val, ', ' ORDER BY step) FROM p06.reads), '-'));
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p06.ticket WHERE status = 'open'$$) = '3', 'đơn mở mới của B vẫn được commit (3 đơn mở)');
