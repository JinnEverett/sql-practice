BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM o01.find_customer_bad($b$' OR '1'='1$b$)$$) = '6', 'xác nhận: hàm cũ _bad bị chèn SQL, trả cả 6 khách');
SELECT pg_temp.ck(pg_temp.val($$SELECT name FROM o01.find_customer('binh@x.vn')$$) = 'Bình', 'tìm đúng email binh@x.vn → Bình');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM o01.find_customer($b$' OR '1'='1$b$)$$) = '0', 'payload '' OR ''1''=''1 trả 0 dòng');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM o01.find_customer($b$x'; DROP TABLE o01.orders; /*$b$)$$) = '0', 'payload có DROP TABLE trả 0 dòng');
SELECT pg_temp.ck(to_regclass('o01.orders') IS NOT NULL, 'bảng orders vẫn còn');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM o01.find_customer($b$an@x.vn' OR email='em@x.vn$b$)$$) = '0', 'payload trộn điều kiện không khớp email nào');
SELECT pg_temp.ck(pg_temp.val($$SELECT name FROM o01.find_customer('chi@x.vn', 'name')$$) = 'Chi', 'p_order_by = name chạy được');
SELECT pg_temp.ck(pg_temp.fails($$SELECT * FROM o01.find_customer('an@x.vn', 'id; DROP TABLE o01.orders')$$, '22023'), 'p_order_by ngoài whitelist bị từ chối (22023)');
SELECT pg_temp.ck(pg_temp.fails($$SELECT * FROM o01.find_customer('an@x.vn', 'password_hash')$$, '22023'), 'không cho sắp xếp theo cột ngoài danh sách (password_hash)');
ROLLBACK;
