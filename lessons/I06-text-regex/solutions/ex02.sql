-- db: shop_s
-- ordered
-- Giải thích: toán tử ~ là so khớp regex (có phân biệt hoa thường; ~* thì không). Neo ^…$ để khớp CẢ chuỗi.
--   \d = chữ số, {9} = đúng 9 lần, \s = khoảng trắng. CASE xét NULL trước.
-- Bẫy: thiếu ^$ → chuỗi dài hơn vẫn khớp; phone LIKE '0%' coi mọi chuỗi bắt đầu bằng 0 là hợp lệ.
SELECT CASE
         WHEN phone IS NULL THEN '(trống)'
         WHEN phone ~ '^0\d{9}$' THEN 'nội địa 0xxxxxxxxx'
         WHEN phone ~ '^\+84\s\d{9}$' THEN 'quốc tế +84'
         ELSE 'khác'
       END AS dinh_dang,
       count(*) AS n_users
FROM users
GROUP BY 1
ORDER BY n_users DESC;
