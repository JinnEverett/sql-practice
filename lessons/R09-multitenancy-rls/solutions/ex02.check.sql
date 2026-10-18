BEGIN;
:ans
;
SET LOCAL ROLE r09_app;
SELECT set_config('app.tenant_id', '1', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.invoices$$) = '3', 'tenant 1 thấy đúng 3 hóa đơn của mình');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.invoices WHERE tenant_id <> 1$$) = '0', 'tenant 1 không thấy hóa đơn tenant khác kể cả khi tự viết WHERE');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r09.invoices (tenant_id, customer_id, amount) VALUES (1, 1, 10)$$), 'tenant 1 chèn hóa đơn cho chính mình: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r09.invoices (tenant_id, customer_id, amount) VALUES (2, 3, 10)$$, '42501'), 'tenant 1 chèn hóa đơn mang tenant_id 2 bị chặn (42501)');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE r09.invoices SET tenant_id = 2 WHERE id = 1$$, '42501'), 'tenant 1 đổi hóa đơn của mình sang tenant 2 bị chặn (42501)');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r09.invoices SET amount = 0 WHERE tenant_id = 2$$), 'tenant 1 UPDATE hóa đơn tenant 2: không lỗi nhưng không tác động');
SELECT pg_temp.ck(pg_temp.ok($$DELETE FROM r09.invoices WHERE tenant_id = 3$$), 'tenant 1 DELETE hóa đơn tenant 3: không lỗi nhưng không tác động');
SELECT set_config('app.tenant_id', '2', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) || ':' || coalesce(sum(amount), 0)::int FROM r09.invoices$$) = '2:900', 'tenant 2 thấy đúng 2 hóa đơn (400 + 500), dữ liệu tenant khác không bị sửa/xóa');
RESET ROLE;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.invoices$$) = '8', 'superuser (bypass RLS) thấy tất cả: 7 + 1 dòng vừa chèn');
ROLLBACK;
