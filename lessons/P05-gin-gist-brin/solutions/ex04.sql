-- db: shop_m
-- mode: check
-- Giải thích: index trên biểu thức to_tsvector('simple', name) → GIN lưu token → danh sách dòng. Truy vấn phải dùng đúng biểu thức và cùng cấu hình ('simple' là hằng regconfig),
--   nếu không planner không khớp được. 10 buffers thay vì 398.
-- Bẫy: index với cấu hình 'english' (tokenize/stem khác, không khớp biểu thức → Seq Scan); B-tree trên name; to_tsvector không ghi cấu hình (STABLE, không tạo index được).
CREATE INDEX ON products USING gin (to_tsvector('simple', name));
