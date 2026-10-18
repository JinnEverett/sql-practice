BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r01.customers$$) = '4', 'customers có 4 dòng');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r01.products$$) = '3', 'products có 3 dòng');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r01.orders$$) = '6', 'orders có 6 dòng');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r01.order_lines$$) = '10', 'order_lines có 10 dòng');
SELECT pg_temp.ck(pg_temp.val($$SELECT city FROM r01.customers WHERE customer_id = 2$$) = 'Sài Gòn', 'khách 2: lấy city ở dòng mới nhất (Sài Gòn)');
SELECT pg_temp.ck(pg_temp.val($$SELECT name FROM r01.products WHERE sku = 'VO'$$) = 'Vở 96 trang', 'sản phẩm VO: lấy tên ở dòng mới nhất');
SELECT pg_temp.ck(pg_temp.val($$SELECT unit_price::int FROM r01.order_lines WHERE order_id = 3 AND sku = 'BUT'$$) = '5500', 'giá lúc bán 5500 được giữ ở dòng hàng');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.order_lines VALUES (1, 'XYZ', 1000, 1)$$, '23503'), 'sku không tồn tại bị chặn (FK)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.order_lines VALUES (99, 'BUT', 1000, 1)$$, '23503'), 'đơn không tồn tại bị chặn (FK)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.order_lines VALUES (1, 'BUT', 1000, 1)$$, '23505'), 'trùng (order_id, sku) bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.order_lines VALUES (1, 'THUOC', 1000, 0)$$, '23514'), 'qty = 0 bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.orders VALUES (50, '2026-04-01', 99)$$, '23503'), 'đơn của khách không tồn tại bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.orders (order_id, ordered_on) VALUES (51, '2026-04-01')$$, '23502'), 'đơn thiếu customer_id bị chặn');
ROLLBACK;
