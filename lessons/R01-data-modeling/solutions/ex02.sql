-- db: lab
-- reset
-- ordered
-- expect-rows: 2
-- Giải thích: phụ thuộc hàm customer_id → (name, city) và sku → product_name phải đúng: mỗi khóa chỉ ứng với MỘT giá trị.
--   Vi phạm = cùng khóa có ≥ 2 giá trị khác nhau (update anomaly đã xảy ra). Đếm count(DISTINCT …) theo khóa.
--   unit_price KHÔNG nằm trong danh sách vi phạm: giá lúc bán (snapshot) được phép khác nhau giữa các dòng.
-- Bẫy: đưa unit_price vào kiểm tra → báo nhầm; dùng count(*) thay vì count(DISTINCT) → mọi khóa lặp lại đều bị báo.
SELECT 'customer' AS entity, customer_id::text AS key, 'customer_city' AS attribute, count(DISTINCT customer_city) AS n_values
FROM r01.flat_sales GROUP BY customer_id HAVING count(DISTINCT customer_city) > 1
UNION ALL
SELECT 'customer', customer_id::text, 'customer_name', count(DISTINCT customer_name)
FROM r01.flat_sales GROUP BY customer_id HAVING count(DISTINCT customer_name) > 1
UNION ALL
SELECT 'product', sku, 'product_name', count(DISTINCT product_name)
FROM r01.flat_sales GROUP BY sku HAVING count(DISTINCT product_name) > 1
ORDER BY entity, key, attribute;
