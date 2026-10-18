BEGIN;
:ans
;
UPDATE i09.products SET price = 160000 WHERE id = 1;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.price_history$$) = '1', 'đổi giá 1 sản phẩm → 1 dòng lịch sử');
SELECT pg_temp.ck(pg_temp.val($$SELECT old_price || '>' || new_price FROM i09.price_history WHERE product_id = 1$$) = '150000.00>160000.00', 'ghi đúng giá cũ và giá mới');
UPDATE i09.products SET name = 'Chuột không dây' WHERE id = 1;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.price_history$$) = '1', 'đổi tên (không đổi giá) không ghi lịch sử');
UPDATE i09.products SET price = price WHERE id = 2;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.price_history$$) = '1', 'SET price = price (giá không đổi) không ghi lịch sử');
UPDATE i09.products SET price = price * 2;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.price_history$$) = '4', 'UPDATE hàng loạt 3 sản phẩm → thêm 3 dòng (tổng 4)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(DISTINCT product_id) FROM i09.price_history$$) = '3', 'đủ 3 sản phẩm có lịch sử');
INSERT INTO i09.products VALUES (4, 'Webcam', 500000, 1);
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.price_history$$) = '4', 'INSERT sản phẩm mới không ghi lịch sử');
SELECT pg_temp.ck(pg_temp.val($$SELECT tgtype & 1 FROM pg_trigger WHERE tgrelid = 'i09.products'::regclass AND NOT tgisinternal$$) = '1', 'trigger là FOR EACH ROW');
ROLLBACK;
