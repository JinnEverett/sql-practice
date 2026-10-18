BEGIN;
:ans
;
SET LOCAL ROLE r09_app;
SELECT set_config('app.tenant_id', '1', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.payment_totals$$) = '1', 'tenant 1 chỉ thấy 1 dòng tổng hợp (của mình)');
SELECT pg_temp.ck(pg_temp.val($$SELECT total::int FROM r09.payment_totals$$) = '30', 'tổng của tenant 1 là 30 (10 + 20)');
SELECT set_config('app.tenant_id', '2', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT tenant_id || ':' || total::int FROM r09.payment_totals$$) = '2:70', 'tenant 2: chỉ thấy 2:70');
SELECT set_config('app.tenant_id', '', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.payment_totals$$) = '0', 'chưa xác định tenant: không thấy gì');
ROLLBACK;
