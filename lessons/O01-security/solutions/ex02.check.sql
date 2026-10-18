BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.as_val('o01_ro', $$SELECT count(*) FROM o01.orders$$) = '10', 'đọc được bảng có sẵn');
CREATE TABLE o01.shipments (id int PRIMARY KEY, order_id int);
INSERT INTO o01.shipments VALUES (1, 1);
SELECT pg_temp.ck(pg_temp.as_val('o01_ro', $$SELECT count(*) FROM o01.shipments$$) = '1', 'đọc được bảng mới tạo sau (shipments) mà không cần GRANT lại');
SELECT pg_temp.ck(pg_temp.as_fails('o01_ro', $$INSERT INTO o01.shipments VALUES (2, 2)$$, '42501'), 'bảng mới vẫn chỉ đọc (không INSERT được)');
SELECT pg_temp.ck((SELECT count(*) FROM pg_default_acl d WHERE d.defaclnamespace = 'o01'::regnamespace AND d.defaclobjtype = 'r') >= 1, 'có default ACL cho bảng trong schema o01');
ROLLBACK;
