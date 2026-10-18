-- db: shop_s
-- ordered
-- Giải thích: window không ORDER BY → frame là CẢ partition → avg/max của cả danh mục gắn vào từng dòng. Không cần GROUP BY,
--   mỗi sản phẩm vẫn là một dòng.
-- Bẫy: GROUP BY category_id rồi JOIN lại (dài, dễ sai); thêm ORDER BY vào OVER → avg thành trung bình lũy kế.
SELECT c.name AS category, p.id, p.price,
       round(avg(p.price) OVER (PARTITION BY p.category_id)) AS avg_price,
       round(p.price - avg(p.price) OVER (PARTITION BY p.category_id)) AS diff_from_avg,
       round(100.0 * p.price / max(p.price) OVER (PARTITION BY p.category_id), 1) AS pct_of_max
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE p.is_active AND c.name IN ('Trà', 'Cà phê')
ORDER BY category, p.price DESC, p.id;
