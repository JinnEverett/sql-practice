-- db: shop_s
-- ordered
-- Giải thích: row_number() OVER (PARTITION BY email_norm ORDER BY created_at, id): bản rn = 1 là bản giữ lại; rn > 1 là bản trùng.
--   Lấy id bản gốc bằng cách JOIN lại với chính tập đã đánh số tại rn = 1 (I04 sẽ có first_value gọn hơn).
-- Bẫy: giữ id nhỏ nhất thay vì đăng ký sớm nhất; quên trim/lower khi chuẩn hóa.
WITH n AS (
  SELECT id, lower(trim(email)) AS email_norm,
         row_number() OVER (PARTITION BY lower(trim(email)) ORDER BY created_at, id) AS rn
  FROM users
)
SELECT d.id AS dup_id, k.id AS keep_id, d.email_norm
FROM n d
JOIN n k ON k.email_norm = d.email_norm AND k.rn = 1
WHERE d.rn > 1
ORDER BY dup_id;
