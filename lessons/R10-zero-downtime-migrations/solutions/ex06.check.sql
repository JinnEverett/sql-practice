BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r10.orders2 WHERE amount_vnd IS DISTINCT FROM total$$) = '0', 'mọi dòng cũ đã có amount_vnd = total (kể cả total NULL)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r10.orders2 (id, total) VALUES (10, 111)$$) AND pg_temp.val($$SELECT amount_vnd::int FROM r10.orders2 WHERE id = 10$$) = '111', 'code cũ INSERT chỉ total → amount_vnd theo');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r10.orders2 (id, amount_vnd) VALUES (11, 222)$$) AND pg_temp.val($$SELECT total::int FROM r10.orders2 WHERE id = 11$$) = '222', 'code mới INSERT chỉ amount_vnd → total theo');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r10.orders2 SET total = 333 WHERE id = 10$$) AND pg_temp.val($$SELECT amount_vnd::int FROM r10.orders2 WHERE id = 10$$) = '333', 'code cũ UPDATE total → amount_vnd theo');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r10.orders2 SET amount_vnd = 444 WHERE id = 11$$) AND pg_temp.val($$SELECT total::int FROM r10.orders2 WHERE id = 11$$) = '444', 'code mới UPDATE amount_vnd → total theo');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r10.orders2 SET total = NULL WHERE id = 10$$) AND pg_temp.val($$SELECT (amount_vnd IS NULL)::text FROM r10.orders2 WHERE id = 10$$) = 'true', 'đặt total về NULL thì amount_vnd cũng NULL');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r10.orders2 (id, total, amount_vnd) VALUES (12, 5, 5)$$), 'ghi cả hai cột cùng giá trị: được');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r10.orders2 SET id = id WHERE id = 1$$) AND pg_temp.val($$SELECT total::int || ':' || amount_vnd::int FROM r10.orders2 WHERE id = 1$$) = '100000:100000', 'UPDATE không đổi cột nào: giữ nguyên');
ROLLBACK;
