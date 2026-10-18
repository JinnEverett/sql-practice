BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.as_val('o01_support', $$SELECT count(*) FROM o01.v_customers_public$$) = '6', 'o01_support đọc được view (6 khách)');
SELECT pg_temp.ck((SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema = 'o01' AND table_name = 'v_customers_public') = 'id,name,tenant_id', 'view chỉ có id, name, tenant_id');
SELECT pg_temp.ck(pg_temp.as_fails('o01_support', $$SELECT count(*) FROM o01.customers$$, '42501'), 'o01_support không đọc được bảng customers (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_support', $$SELECT count(*) FROM o01.orders$$, '42501'), 'o01_support không đọc được bảng orders (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_support', $$UPDATE o01.v_customers_public SET name = 'x'$$, '42501'), 'o01_support không ghi qua view (42501)');
ROLLBACK;
