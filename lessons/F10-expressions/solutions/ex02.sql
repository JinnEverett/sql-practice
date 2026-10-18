-- db: shop_s
-- ordered
-- Giải thích: CASE gom các cách viết của TP.HCM về một tên; ELSE coalesce(city, '(không rõ)') giữ các thành phố khác và đặt nhãn cho NULL.
--   GROUP BY 1 gom theo biểu thức đã chuẩn hóa (không phải cột city gốc).
-- Bẫy: CASE thiếu ELSE → mọi thành phố khác thành NULL; quên NULL → nhóm NULL không có nhãn; GROUP BY city gốc.
SELECT CASE
         WHEN city IN ('TP. Hồ Chí Minh', 'TP.HCM', 'HCM', 'Ho Chi Minh') THEN 'TP. Hồ Chí Minh'
         ELSE coalesce(city, '(không rõ)')
       END AS city_norm,
       count(*) AS n_users
FROM users
WHERE country = 'VN'
GROUP BY 1
ORDER BY n_users DESC, city_norm;
