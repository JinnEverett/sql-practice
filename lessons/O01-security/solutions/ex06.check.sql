BEGIN;
:ans
;
SELECT set_config('app.tenant_id', '1', true);
SELECT pg_temp.ck(pg_temp.as_val('o01_tenant_app', $$SELECT count(*) FROM o01.orders$$) = '6', 'tenant 1 thấy 6 đơn của mình');
SELECT pg_temp.ck(pg_temp.as_val('o01_tenant_app', $$SELECT count(*) FROM o01.orders WHERE tenant_id = 2$$) = '0', 'tenant 1 không thấy đơn tenant 2 kể cả khi lọc thẳng');
SELECT pg_temp.ck(pg_temp.as_ok('o01_tenant_app', $$INSERT INTO o01.orders VALUES (50, 1, 1, 'paid', 1)$$), 'tenant 1 tạo được đơn cho tenant 1');
SELECT pg_temp.ck(pg_temp.as_fails('o01_tenant_app', $$INSERT INTO o01.orders VALUES (51, 2, 4, 'paid', 1)$$, '42501'), 'tenant 1 không tạo được đơn cho tenant 2 (42501, WITH CHECK)');
SELECT set_config('app.tenant_id', '2', true);
SELECT pg_temp.ck(pg_temp.as_val('o01_tenant_app', $$SELECT count(*) FROM o01.orders$$) = '4', 'chuyển sang tenant 2: thấy 4 đơn');
SELECT set_config('app.tenant_id', '', true);
SELECT pg_temp.ck(pg_temp.as_val('o01_tenant_app', $$SELECT count(*) FROM o01.orders$$) = '0', 'tenant_id rỗng: thấy 0 đơn (không lỗi)');
RESET app.tenant_id;
SELECT pg_temp.ck(pg_temp.as_val('o01_tenant_app', $$SELECT count(*) FROM o01.orders$$) = '0', 'chưa đặt app.tenant_id: thấy 0 đơn (không lỗi)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM o01.orders$$) = '11', 'superuser vẫn thấy cả 11 đơn (10 + đơn 50 vừa thêm): RLS không áp cho superuser');
ROLLBACK;
