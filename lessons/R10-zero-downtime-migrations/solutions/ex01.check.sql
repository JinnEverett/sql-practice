SELECT relfilenode AS rf0 FROM pg_class WHERE oid = 'r10.orders'::regclass \gset
SELECT min(xmin::text) AS xmin0 FROM r10.orders \gset
BEGIN;
:ans
;
SELECT pg_temp.ck((SELECT relfilenode FROM pg_class WHERE oid = 'r10.orders'::regclass) = :rf0, 'bảng KHÔNG bị viết lại (relfilenode không đổi)');
SELECT pg_temp.ck((SELECT count(*) FROM r10.orders WHERE xmin::text <> :'xmin0') = 0, 'không có dòng nào bị UPDATE (xmin của mọi dòng không đổi)');
SELECT pg_temp.ck(pg_temp.val($$SELECT is_nullable || ':' || data_type FROM information_schema.columns WHERE table_schema = 'r10' AND table_name = 'orders' AND column_name = 'priority'$$) = 'NO:integer', 'cột priority integer NOT NULL');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r10.orders WHERE priority = 0$$) = pg_temp.val($$SELECT count(*) FROM r10.orders$$), 'mọi dòng cũ đọc ra priority = 0');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r10.orders (status, amount, created_at) VALUES ('paid', 1, now())$$), 'chèn dòng mới không cần truyền priority');
ROLLBACK;
