-- db: shop_m
-- mode: check
-- Giải thích: `created_at::date = X` bọc cột trong biểu thức nên index trên created_at vô dụng và Seq Scan 11 929 page. Viết lại thành khoảng nửa mở [X, X+1) trên chính cột:
--   Index Only Scan 14 buffers. (Session ở UTC nên `created_at::date` là ngày UTC; viết lại giữ đúng ngữ nghĩa đó. Muốn ngày giờ VN phải dùng AT TIME ZONE, xem I05.)
-- Bẫy: chỉ tạo index mà giữ nguyên query (không dùng được); viết lại mà quên index; BETWEEN với mốc 23:59:59 làm rớt dòng cuối giây.
CREATE INDEX ON orders (created_at);
-- query
SELECT count(*) FROM orders WHERE created_at >= '2026-09-11' AND created_at < '2026-09-12';
