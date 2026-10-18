-- db: shop_m
-- mode: check
-- Giải thích: điều kiện bọc created_at trong biểu thức nên index trên created_at không dùng được. Index trên đúng biểu thức
--   (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date: 88 buffers cho 6 516 dòng. Biểu thức phải IMMUTABLE: AT TIME ZONE với hằng thì được;
--   created_at::date phụ thuộc TimeZone của session (STABLE) nên Postgres từ chối tạo index.
-- Bẫy: index (created_at); created_at::date (lỗi "functions in index expression must be marked IMMUTABLE"); biểu thức khác múi giờ (UTC) tạo được nhưng không khớp query.
CREATE INDEX orders_vn_date_idx ON orders (((created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date));
