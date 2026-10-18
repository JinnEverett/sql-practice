BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.as_val('o01_ro', $$SELECT count(*) FROM o01.orders$$) = '10', 'o01_ro đọc được o01.orders (10 đơn)');
SELECT pg_temp.ck(pg_temp.as_val('o01_ro', $$SELECT count(*) FROM o01.customers$$) = '6', 'o01_ro đọc được o01.customers');
SELECT pg_temp.ck(pg_temp.as_fails('o01_ro', $$INSERT INTO o01.orders VALUES (99, 1, 1, 'paid', 1)$$, '42501'), 'o01_ro không INSERT được (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_ro', $$UPDATE o01.orders SET status = 'paid'$$, '42501'), 'o01_ro không UPDATE được (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_ro', $$DELETE FROM o01.orders$$, '42501'), 'o01_ro không DELETE được (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_ro', $$CREATE TABLE o01.t_new (x int)$$, '42501'), 'o01_ro không tạo bảng trong o01 (42501)');
SELECT pg_temp.ck(NOT (SELECT rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole FROM pg_roles WHERE rolname = 'o01_ro'), 'o01_ro là NOLOGIN, không superuser/createdb/createrole');
SELECT pg_temp.ck(NOT EXISTS (SELECT 1 FROM pg_class c, aclexplode(c.relacl) a WHERE c.oid = 'o01.orders'::regclass AND a.grantee = 0), 'không cấp quyền cho PUBLIC trên o01.orders');
ROLLBACK;
