BEGIN;
:ans
;
SELECT pg_temp.ck((SELECT relkind FROM pg_class WHERE oid = 'i09.v_orders_vn'::regclass) = 'v', 'v_orders_vn là view (không phải bảng)');
SELECT pg_temp.ck((SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns
                   WHERE table_schema = 'i09' AND table_name = 'v_orders_vn') = 'order_id,customer_name,status,total,order_date',
                  'đúng 5 cột theo thứ tự order_id, customer_name, status, total, order_date');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.v_orders_vn$$) = '9', '9 đơn không bị hủy');
SELECT pg_temp.ck(pg_temp.val($$SELECT order_date::text FROM i09.v_orders_vn WHERE order_id = 1$$) = '2026-09-01', 'đơn 1 (09:00 giờ VN) thuộc ngày 2026-09-01');
SELECT pg_temp.ck(pg_temp.val($$SELECT order_date::text FROM i09.v_orders_vn WHERE order_id = 3$$) = '2026-09-02', 'đơn 3 (03:00+07 ngày 02/09 = 20:00 UTC ngày 01/09) vẫn là ngày 2026-09-02 theo giờ VN');
INSERT INTO i09.orders VALUES (13, 1, 'paid', 1000, '2026-09-10 00:30+07');
SELECT pg_temp.ck(pg_temp.val($$SELECT order_date::text FROM i09.v_orders_vn WHERE order_id = 13$$) = '2026-09-10', 'đơn mới thêm xuất hiện ngay trong view, ngày 2026-09-10 (00:30 giờ VN)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.v_orders_vn WHERE status = 'cancelled'$$) = '0', 'không có đơn cancelled');
ROLLBACK;
