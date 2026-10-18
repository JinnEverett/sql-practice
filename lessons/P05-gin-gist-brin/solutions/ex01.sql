-- db: shop_m
-- mode: check
-- Giải thích: `@>` (chứa) của jsonb chỉ được GIN hỗ trợ. jsonb_path_ops nhỏ hơn (13.9 MB so với 19.6 MB của jsonb_ops) và build nhanh hơn,
--   đủ cho @>; jsonb_ops cần khi dùng thêm `?` (có key) hoặc `?|`/`?&`. 40 dòng khớp → 44 buffers thay vì quét 45 243 page.
-- Bẫy: B-tree trên (properties->>'product_id')::int (đúng cho `= 12345` nhưng planner không dùng cho `@>`); GIN cho khóa/giá trị xuất hiện ở hàng chục % dòng.
CREATE INDEX ON events USING gin (properties jsonb_path_ops);
