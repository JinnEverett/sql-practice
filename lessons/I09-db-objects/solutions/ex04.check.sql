BEGIN;
:ans
;
SELECT pg_temp.ck((SELECT relkind FROM pg_class WHERE oid = 'i09.mv_daily_revenue'::regclass) = 'm', 'mv_daily_revenue là materialized view');
SELECT pg_temp.ck((SELECT string_agg(attname, ',' ORDER BY attnum) FROM pg_attribute WHERE attrelid = 'i09.mv_daily_revenue'::regclass AND attnum > 0) = 'day,n_orders,revenue', 'cột day, n_orders, revenue');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.mv_daily_revenue$$) = '5', '5 ngày có đơn (01–05/09 giờ VN)');
SELECT pg_temp.ck(pg_temp.val($$SELECT revenue FROM i09.mv_daily_revenue WHERE day = '2026-09-01'$$) = '150000.00', 'ngày 01/09: chỉ đơn 1 (đơn 2 bị hủy) = 150000');
INSERT INTO i09.orders VALUES (13, 1, 'paid', 1000000, '2026-09-10 10:00+07');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.mv_daily_revenue WHERE day = '2026-09-10'$$) = '0', 'trước REFRESH, matview còn cũ (chưa thấy ngày 10/09)');
SELECT pg_temp.ck(pg_temp.ok($$REFRESH MATERIALIZED VIEW CONCURRENTLY i09.mv_daily_revenue$$), 'REFRESH MATERIALIZED VIEW CONCURRENTLY chạy được');
SELECT pg_temp.ck(pg_temp.val($$SELECT revenue FROM i09.mv_daily_revenue WHERE day = '2026-09-10'$$) = '1000000.00', 'sau REFRESH thấy ngày 10/09 = 1000000');
ROLLBACK;
