BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO i09.order_lines (order_id, product_id, quantity) VALUES (1, 1, 3)$$), 'mua 3 Chuột (kho 10) thành công');
SELECT pg_temp.ck(pg_temp.val($$SELECT stock FROM i09.products WHERE id = 1$$) = '7', 'kho Chuột còn 7');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO i09.order_lines (order_id, product_id, quantity) VALUES (1, 1, 7)$$), 'mua nốt 7 Chuột (đúng bằng tồn kho) thành công');
SELECT pg_temp.ck(pg_temp.val($$SELECT stock FROM i09.products WHERE id = 1$$) = '0', 'kho Chuột về 0 (không âm)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO i09.order_lines (order_id, product_id, quantity) VALUES (1, 1, 1)$$, '23514'), 'mua thêm 1 khi kho 0 bị chặn (23514)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO i09.order_lines (order_id, product_id, quantity) VALUES (2, 3, 1)$$, '23514'), 'mua Tai nghe (kho 0) bị chặn');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.order_lines$$) = '2', 'các dòng bị chặn không được ghi (còn 2 dòng)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO i09.order_lines (order_id, product_id, quantity) SELECT 3, 2, q FROM (VALUES (4), (4)) v(q)$$, '23514'), 'INSERT 2 dòng 4 + 4 Bàn phím (kho 5): dòng thứ hai làm cả câu lệnh thất bại');
SELECT pg_temp.ck(pg_temp.val($$SELECT stock FROM i09.products WHERE id = 2$$) = '5', 'sau khi cả câu lệnh thất bại, kho Bàn phím vẫn 5');
DELETE FROM i09.order_lines WHERE product_id = 1 AND quantity = 3;
SELECT pg_temp.ck(pg_temp.val($$SELECT stock FROM i09.products WHERE id = 1$$) = '3', 'xóa dòng 3 Chuột → trả 3 vào kho');
ROLLBACK;
