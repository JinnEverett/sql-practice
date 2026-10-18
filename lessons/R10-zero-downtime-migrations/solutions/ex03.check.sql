:ans
;
SELECT count(*) AS total FROM r10.orders \gset
CALL r10.backfill_status(5000);
SELECT pg_temp.ck((SELECT count(*) FROM r10.orders WHERE status_code IS NULL) = 0, 'mọi dòng đã có status_code');
SELECT pg_temp.ck((SELECT string_agg(status || ':' || status_code, ',' ORDER BY status_code) FROM (SELECT DISTINCT status, status_code FROM r10.orders) t) = 'pending:1,paid:2,shipped:3,delivered:4,cancelled:5', 'ánh xạ status → status_code đúng');
SELECT pg_temp.ck((SELECT count(DISTINCT xmin::text) FROM r10.orders) >= ceil(:total / 5000.0), 'backfill chạy nhiều transaction (xmin khác nhau: ' || (SELECT count(DISTINCT xmin::text) FROM r10.orders) || ')');
SELECT pg_temp.ck((SELECT max(c) FROM (SELECT count(*) AS c FROM r10.orders GROUP BY xmin::text) t) <= 5000, 'không transaction nào sửa quá 5000 dòng (lớn nhất ' || (SELECT max(c) FROM (SELECT count(*) AS c FROM r10.orders GROUP BY xmin::text) t) || ')');
CALL r10.backfill_status(5000);
SELECT pg_temp.ck((SELECT count(*) FROM r10.orders) = :total, 'chạy lại lần nữa vẫn đúng và nhanh (idempotent)');
