BEGIN;
:ans
;
SET LOCAL ROLE r09_app;
-- Trường hợp 1: biến phiên chưa từng được đặt trong session này
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.notes$$) = '0', 'chưa đặt app.tenant_id: trả 0 dòng, không lỗi');
SELECT set_config('app.tenant_id', '1', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.notes$$) = '2', 'tenant 1 thấy 2 ghi chú');
SELECT set_config('app.tenant_id', '', true);
-- Trường hợp 2: biến đặt thành chuỗi rỗng
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r09.notes$$) = '0', 'app.tenant_id rỗng: trả 0 dòng, không lỗi');
SELECT set_config('app.tenant_id', '2', true);
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(body, ',') FROM r09.notes$$) = 'ghi chú B', 'tenant 2 thấy đúng ghi chú của mình');
SELECT set_config('app.tenant_id', '', true);
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r09.notes (tenant_id, body) VALUES (1, 'lén')$$, '42501'), 'khi chưa xác định tenant, không ghi được dòng nào (42501)');
ROLLBACK;
