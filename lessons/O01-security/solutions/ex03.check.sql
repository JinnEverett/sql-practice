BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.as_val('o01_app', $$SELECT email FROM o01.customers WHERE id = 1$$) = 'an@x.vn', 'đọc được email khách');
SELECT pg_temp.ck(pg_temp.as_val('o01_app', $$SELECT password_hash FROM o01.customers WHERE id = 1$$) = 'ERROR:42501', 'đọc password_hash bị từ chối (42501)');
SELECT pg_temp.ck(pg_temp.as_val('o01_app', $$SELECT count(*) FROM (SELECT * FROM o01.customers) t$$) = 'ERROR:42501', 'SELECT * trên customers bị từ chối (vì có cột cấm)');
SELECT pg_temp.ck(pg_temp.as_ok('o01_app', $$INSERT INTO o01.orders VALUES (99, 1, 1, 'paid', 50000)$$), 'INSERT đơn mới được');
SELECT pg_temp.ck(pg_temp.as_ok('o01_app', $$UPDATE o01.orders SET status = 'delivered' WHERE id = 99$$), 'UPDATE status được');
SELECT pg_temp.ck(pg_temp.as_fails('o01_app', $$UPDATE o01.orders SET total = 1 WHERE id = 99$$, '42501'), 'UPDATE total bị từ chối (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_app', $$DELETE FROM o01.orders WHERE id = 99$$, '42501'), 'DELETE bị từ chối (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_app', $$TRUNCATE o01.orders$$, '42501'), 'TRUNCATE bị từ chối (42501)');
SELECT pg_temp.ck(pg_temp.as_fails('o01_app', $$INSERT INTO o01.customers VALUES (50, 1, 'X', 'x@x.vn', 'h')$$, '42501'), 'INSERT customers bị từ chối (42501)');
SELECT pg_temp.ck((SELECT rolcanlogin AND NOT rolsuper AND NOT rolcreatedb AND NOT rolcreaterole FROM pg_roles WHERE rolname = 'o01_app'), 'o01_app là LOGIN, không superuser/createdb/createrole');
ROLLBACK;
