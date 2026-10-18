-- db: shop_s
-- ordered
SELECT nhom, id, name, price FROM (
  (SELECT 'đắt' AS nhom, id, name, price FROM products WHERE is_active ORDER BY price DESC, id LIMIT 5)
  UNION ALL
  (SELECT 'rẻ'  AS nhom, id, name, price FROM products WHERE is_active ORDER BY price ASC,  id LIMIT 5)
) t
ORDER BY price DESC, id;
