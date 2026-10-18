BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT i09.apply_discount(1, 10)$$) = '135000.00', 'đơn 1 (paid, 150000) giảm 10% → 135000.00');
SELECT pg_temp.ck(pg_temp.val($$SELECT total FROM i09.orders WHERE id = 1$$) = '135000.00', 'bảng orders đã cập nhật');
SELECT pg_temp.ck(pg_temp.val($$SELECT i09.apply_discount(5, 0)$$) = '750000.00', 'giảm 0% hợp lệ, giữ nguyên tổng');
SELECT pg_temp.ck(pg_temp.val($$SELECT i09.apply_discount(9, 12.5)$$) = '1181250.00', 'đơn 9 (1350000) giảm 12.5% → 1181250.00');
SELECT pg_temp.ck(pg_temp.fails($$SELECT i09.apply_discount(1, 60)$$, '22023'), 'giảm 60% bị từ chối (22023)');
SELECT pg_temp.ck(pg_temp.fails($$SELECT i09.apply_discount(1, -5)$$, '22023'), 'giảm -5% bị từ chối (22023)');
SELECT pg_temp.ck(pg_temp.fails($$SELECT i09.apply_discount(999, 10)$$, 'P0002'), 'đơn không tồn tại → lỗi P0002 (no_data_found)');
SELECT pg_temp.ck(pg_temp.fails($$SELECT i09.apply_discount(3, 10)$$, 'P0002'), 'đơn đã giao (delivered) không được giảm giá → P0002');
SELECT pg_temp.ck(pg_temp.val($$SELECT total FROM i09.orders WHERE id = 3$$) = '450000.00', 'đơn 3 giữ nguyên tổng sau khi bị từ chối');
ROLLBACK;
