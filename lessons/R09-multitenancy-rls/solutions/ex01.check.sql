BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r09.invoices (tenant_id, customer_id, amount) VALUES (1, 2, 50)$$), 'hóa đơn tenant 1 cho khách tenant 1: được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r09.invoices (tenant_id, customer_id, amount) VALUES (2, 3, 60)$$), 'hóa đơn tenant 2 cho khách tenant 2: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r09.invoices (tenant_id, customer_id, amount) VALUES (1, 3, 70)$$, '23503'), 'hóa đơn tenant 1 trỏ vào khách tenant 2 bị chặn (23503)');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE r09.invoices SET customer_id = 5 WHERE id = 1$$, '23503'), 'sửa hóa đơn tenant 1 sang khách tenant 3 bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE r09.customers SET tenant_id = 3 WHERE id = 1$$, '23503'), 'chuyển khách đang có hóa đơn sang tenant khác bị chặn');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.invoices$$) = '9', 'dữ liệu hợp lệ hiện có còn nguyên (7 + 2 dòng vừa thêm)');
ROLLBACK;
