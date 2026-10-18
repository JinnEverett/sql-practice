BEGIN;
:ans
;
-- Hai người cùng mở sản phẩm 3 khi version = 0
SELECT pg_temp.ck(r08.update_price(3, 0, 25000) IS TRUE, 'người thứ nhất (version 0) lưu được');
SELECT pg_temp.ck(r08.update_price(3, 0, 30000) IS FALSE, 'người thứ hai vẫn giữ version 0: bị từ chối (false), không ghi đè');
SELECT pg_temp.ck(pg_temp.val($$SELECT price::int || ':' || version FROM r08.products WHERE id = 3$$) = '25000:1', 'giá là 25000 và version tăng lên 1');
SELECT pg_temp.ck(r08.update_price(3, 1, 27000) IS TRUE, 'người thứ hai đọc lại (version 1) rồi lưu được');
SELECT pg_temp.ck(pg_temp.val($$SELECT price::int || ':' || version FROM r08.products WHERE id = 3$$) = '27000:2', 'giá 27000, version 2');
SELECT pg_temp.ck(r08.update_price(999, 0, 1) IS FALSE, 'sản phẩm không tồn tại: false, không lỗi');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r08.products WHERE version <> 0$$) = '1', 'sản phẩm khác không bị đụng');
ROLLBACK;
