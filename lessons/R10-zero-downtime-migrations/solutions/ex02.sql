-- db: lab
-- mode: check
-- reset
-- Giải thích: `ALTER COLUMN … SET NOT NULL` phải quét cả bảng để chắc không có NULL, trong khi giữ ACCESS EXCLUSIVE (chặn cả đọc lẫn ghi suốt thời gian quét).
--   Trình tự an toàn (Postgres 12+): (1) ADD CONSTRAINT … CHECK (col IS NOT NULL) NOT VALID — chỉ cần khóa ngắn, từ giờ dòng mới/sửa phải thỏa;
--   (2) VALIDATE CONSTRAINT — quét bảng nhưng chỉ cần khóa SHARE UPDATE EXCLUSIVE (đọc/ghi vẫn chạy bình thường);
--   (3) SET NOT NULL — Postgres thấy đã có CHECK được xác thực nên BỎ QUA bước quét; (4) DROP CONSTRAINT CHECK thừa.
-- Bẫy: SET NOT NULL trực tiếp (quét bảng dưới ACCESS EXCLUSIVE); quên bước (4) để lại ràng buộc thừa; thêm CHECK mà không NOT VALID (quét dưới khóa mạnh).
ALTER TABLE r10.orders ADD CONSTRAINT customer_ref_not_null CHECK (customer_ref IS NOT NULL) NOT VALID;
ALTER TABLE r10.orders VALIDATE CONSTRAINT customer_ref_not_null;
ALTER TABLE r10.orders ALTER COLUMN customer_ref SET NOT NULL;
ALTER TABLE r10.orders DROP CONSTRAINT customer_ref_not_null;
