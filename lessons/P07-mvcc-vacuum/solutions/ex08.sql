-- db: shop_m
-- mode: manual
-- Demo: bảng tạm sao chép từ orders; đo kích thước sau UPDATE rồi sau VACUUM (dùng `\timing` để đo thời gian). Xóa bảng khi xong.
CREATE TABLE scratch_orders AS SELECT * FROM orders;
ALTER TABLE scratch_orders ADD PRIMARY KEY (id);
ALTER TABLE scratch_orders SET (autovacuum_enabled = false);
UPDATE scratch_orders SET total_amount = total_amount + 1;
SELECT pg_relation_size('scratch_orders') / 8192 AS heap_pages, pg_relation_size('scratch_orders_pkey') / 8192 AS pk_pages;
VACUUM scratch_orders;
SELECT pg_relation_size('scratch_orders') / 8192 AS heap_pages_after_vacuum;
DROP TABLE scratch_orders;
