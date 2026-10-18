-- db: shop_s
-- ordered
-- Giải thích: attributes ? 'color' kiểm tra CÓ key; ->> lấy giá trị. Sản phẩm không có key color gom vào '(không có)'.
-- Bẫy: quên is_active; dùng attributes->'color' (jsonb, có ngoặc kép) làm nhãn.
SELECT coalesce(attributes->>'color', '(không có)') AS color, count(*) AS n_products
FROM products
WHERE is_active
GROUP BY 1
ORDER BY n_products DESC, color;
