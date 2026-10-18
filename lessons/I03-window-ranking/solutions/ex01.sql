-- db: shop_s
-- ordered
-- Giải thích: row_number() OVER (PARTITION BY category_id ORDER BY price DESC, id) đánh số lại từ 1 trong MỖI danh mục.
--   Window function chạy SAU WHERE/GROUP BY nên không lọc được trực tiếp trong WHERE: phải bọc subquery/CTE rồi lọc rn <= 3.
--   Thêm id vào ORDER BY của window để thứ tự xác định khi trùng giá.
-- Bẫy: WHERE row_number() … <= 3 → lỗi "window functions are not allowed in WHERE"; quên PARTITION BY → top 3 toàn bảng.
SELECT category_id, id, name, price, rn
FROM (
  SELECT category_id, id, name, price,
         row_number() OVER (PARTITION BY category_id ORDER BY price DESC, id) AS rn
  FROM products
  WHERE is_active
) t
WHERE rn <= 3
ORDER BY category_id, rn;
