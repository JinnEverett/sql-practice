BEGIN;
:ans
;
-- có index nào trên bảng t mà cột ĐẦU TIÊN là c?
CREATE FUNCTION pg_temp.has_leading_index(t regclass, c text) RETURNS boolean LANGUAGE sql AS $$
  SELECT EXISTS (SELECT 1 FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
                 WHERE i.indrelid = t AND a.attname = c)
$$;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.c_orders (id, customer_id) OVERRIDING SYSTEM VALUE VALUES (1, 1), (2, 1), (3, 2)$$), 'tạo đơn cho khách có thật');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.c_orders (id, customer_id) OVERRIDING SYSTEM VALUE VALUES (50, 99)$$, '23503'), 'đơn cho khách không tồn tại bị chặn (23503)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.c_orders (id) OVERRIDING SYSTEM VALUE VALUES (10)$$, '23502'), 'đơn thiếu customer_id bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.c_order_items VALUES (1, 1, 1, 2), (1, 2, 2, 1), (2, 1, 1, 1)$$), 'thêm dòng hàng hợp lệ');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.c_order_items VALUES (1, 1, 3, 1)$$, '23505'), 'trùng (order_id, line_no) bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.c_order_items VALUES (3, 1, 1, 0)$$, '23514'), 'quantity = 0 bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.c_order_items VALUES (99, 1, 1, 1)$$, '23503'), 'dòng hàng cho đơn không tồn tại bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$DELETE FROM f09.c_products WHERE id = 1$$, '23'), 'không xóa được sản phẩm đã bán');
SELECT pg_temp.ck(pg_temp.ok($$DELETE FROM f09.c_products WHERE id = 3$$), 'xóa được sản phẩm chưa bán');
SELECT pg_temp.ck(pg_temp.fails($$DELETE FROM f09.c_customers WHERE id = 1$$, '23'), 'không xóa được khách còn đơn');
SELECT pg_temp.ck(pg_temp.ok($$DELETE FROM f09.c_orders WHERE id = 1$$), 'xóa đơn 1');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM f09.c_order_items WHERE order_id = 1$$) = '0', 'xóa đơn thì dòng hàng tự mất (CASCADE)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM f09.c_order_items$$) = '1', 'dòng hàng của đơn khác còn nguyên');
SELECT pg_temp.ck(pg_temp.has_leading_index('f09.c_orders', 'customer_id'), 'có index cho c_orders.customer_id');
SELECT pg_temp.ck(pg_temp.has_leading_index('f09.c_order_items', 'product_id'), 'có index cho c_order_items.product_id');
SELECT pg_temp.ck(pg_temp.has_leading_index('f09.c_order_items', 'order_id'), 'c_order_items.order_id có index dùng được (cột đầu của PK)');
ROLLBACK;
