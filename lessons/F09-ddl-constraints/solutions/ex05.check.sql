BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.order_lines (id, quantity, unit_price, discount_pct) OVERRIDING SYSTEM VALUE VALUES (1, 2, 100000, 10)$$), 'chèn (2, 100000, 10%)');
SELECT pg_temp.ck(pg_temp.val($$SELECT line_total FROM f09.order_lines WHERE id = 1$$) = '180000.00', 'line_total = 180000.00');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.order_lines (id, quantity, unit_price) OVERRIDING SYSTEM VALUE VALUES (2, 3, 33333.33)$$), 'chèn không ghi discount (mặc định 0)');
SELECT pg_temp.ck(pg_temp.val($$SELECT line_total FROM f09.order_lines WHERE id = 2$$) = '99999.99', 'line_total = 99999.99');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.order_lines (id, quantity, unit_price, discount_pct) OVERRIDING SYSTEM VALUE VALUES (3, 3, 33333, 12.5)$$), 'chèn discount lẻ 12.5%');
SELECT pg_temp.ck(pg_temp.val($$SELECT line_total FROM f09.order_lines WHERE id = 3$$) = '87499.13', 'line_total = 87499.13 (3 × 33333 × 0.875 = 87499.125, làm tròn 2 chữ số)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.order_lines (quantity, unit_price, line_total) VALUES (1, 1, 999)$$, '428C9'), 'ghi tay line_total bị chặn (428C9)');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE f09.order_lines SET quantity = 3 WHERE id = 1$$), 'đổi quantity của dòng 1 thành 3');
SELECT pg_temp.ck(pg_temp.val($$SELECT line_total FROM f09.order_lines WHERE id = 1$$) = '270000.00', 'line_total tự cập nhật = 270000.00');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.order_lines (quantity, unit_price, discount_pct) VALUES (1, 1, 101)$$, '23514'), 'discount 101 bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.order_lines (quantity, unit_price) VALUES (0, 1)$$, '23514'), 'quantity 0 bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.order_lines (quantity, unit_price, discount_pct) VALUES (1, 1, NULL)$$, '23502'), 'discount NULL bị chặn');
ROLLBACK;
