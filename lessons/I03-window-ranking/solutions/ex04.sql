-- db: shop_s
-- ordered
-- Giải thích: bước 1 tính tổng chi tiêu theo khách kèm city đã chuẩn hóa (F10). Bước 2 xếp hạng trong từng thành phố
--   (PARTITION BY city_norm). Bước 3 lọc hạng ≤ 3. Đây là mẫu top-N mỗi nhóm kinh điển.
-- Bẫy: PARTITION BY city gốc → TP.HCM bị chia thành 4 nhóm; quên loại khách không có city.
WITH spent AS (
  SELECT CASE WHEN u.city IN ('TP. Hồ Chí Minh', 'TP.HCM', 'HCM', 'Ho Chi Minh') THEN 'TP. Hồ Chí Minh' ELSE u.city END AS city_norm,
         u.id AS user_id, u.full_name, sum(o.total_amount) AS total_spent
  FROM users u
  JOIN orders o ON o.user_id = u.id AND o.status = 'delivered'
  WHERE u.country = 'VN' AND u.city IS NOT NULL
  GROUP BY 1, u.id, u.full_name
), ranked AS (
  SELECT *, row_number() OVER (PARTITION BY city_norm ORDER BY total_spent DESC, user_id) AS rnk
  FROM spent
)
SELECT city_norm, user_id, full_name, total_spent, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY city_norm, rnk;
