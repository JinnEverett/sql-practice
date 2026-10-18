BEGIN;
:ans
;
SET LOCAL ROLE r09_support;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.payments$$) = '5', 'hỗ trợ thấy tất cả 5 payment của mọi tenant');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r09.payments (tenant_id, amount) VALUES (1, 1)$$, '42501'), 'hỗ trợ không ghi được (42501)');
RESET ROLE;
SET LOCAL ROLE r09_app;
SELECT set_config('app.tenant_id', '1', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.payments$$) = '2', 'ứng dụng (tenant 1) vẫn chỉ thấy 2 payment của mình');
SELECT set_config('app.tenant_id', '3', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.payments$$) = '1', 'ứng dụng (tenant 3) vẫn chỉ thấy 1 payment');
ROLLBACK;
