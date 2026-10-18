BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.addresses (id, user_id, line) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'Q1'), (2, 1, 'Q3'), (3, 1, 'Thủ Đức')$$), 'ba địa chỉ thường cho cùng khách: được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.addresses (id, user_id, line, is_default) OVERRIDING SYSTEM VALUE VALUES (4, 1, 'Nhà', true)$$), 'một địa chỉ mặc định: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.addresses (id, user_id, line, is_default) OVERRIDING SYSTEM VALUE VALUES (5, 1, 'Công ty', true)$$, '23505'), 'địa chỉ mặc định thứ hai bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE f09.addresses SET is_default = true WHERE id = 2$$, '23505'), 'sửa địa chỉ thường thành mặc định khi đã có mặc định: bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.addresses (id, user_id, line, is_default) OVERRIDING SYSTEM VALUE VALUES (6, 2, 'Hà Nội', true)$$), 'khách khác có mặc định riêng: được');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE f09.addresses SET is_default = false WHERE id = 4$$), 'bỏ mặc định cũ');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE f09.addresses SET is_default = true WHERE id = 2$$), 'đặt mặc định mới');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.addresses (id, user_id, line, is_default) OVERRIDING SYSTEM VALUE VALUES (7, 3, 'x', NULL)$$, '23502'), 'is_default NULL bị chặn');
ROLLBACK;
