-- db: shop_s
-- ordered
-- Giải thích: -> trả về jsonb, ->> trả về text. Muốn số thì lấy text rồi ép: (attributes->>'weight_g')::int.
--   Key không tồn tại → NULL (không lỗi), nên warranty_months tự ra NULL với sản phẩm không có bảo hành.
-- Bẫy: (attributes->'weight_g')::int cũng chạy được (jsonb number → int) nhưng attributes->'color' ra '"đen"' có ngoặc kép.
SELECT id,
       attributes->>'color' AS color,
       attributes->>'size' AS size,
       (attributes->>'weight_g')::int AS weight_g,
       (attributes->>'warranty_months')::int AS warranty_months
FROM products
WHERE id <= 10
ORDER BY id;
