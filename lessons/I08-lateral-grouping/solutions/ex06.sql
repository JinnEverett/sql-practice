-- db: shop_s
-- ordered
-- Giải thích: LEFT JOIN LATERAL (… LIMIT 1) ON true: với mỗi danh mục lấy sản phẩm đang bán đắt nhất; danh mục không có sản phẩm
--   vẫn giữ (cột bên phải NULL). "ON true" vì điều kiện nối đã nằm trong subquery.
-- Bẫy: CROSS JOIN LATERAL (= INNER) làm mất danh mục rỗng (danh mục gốc không chứa sản phẩm trực tiếp).
SELECT c.id AS category_id, c.name AS category, p.id AS product_id, p.name AS product_name, p.price
FROM categories c
LEFT JOIN LATERAL (
  SELECT id, name, price
  FROM products
  WHERE category_id = c.id AND is_active
  ORDER BY price DESC, id
  LIMIT 1
) p ON true
ORDER BY c.id;
