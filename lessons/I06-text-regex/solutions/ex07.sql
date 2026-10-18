-- db: shop_s
-- ordered
-- Giải thích: phát hiện bằng so sánh với dạng chuẩn hóa: email <> lower(email) (có chữ hoa), email <> trim(email) (thừa khoảng trắng).
--   Hoặc regex: email ~ '[A-Z]', email ~ '^\s|\s$'. CASE gán nhãn, kết hợp cả hai.
-- Bẫy: chỉ kiểm tra một loại lỗi; dùng ILIKE/không phân biệt hoa thường để tìm chữ hoa (luôn khớp).
SELECT id, email,
       CASE
         WHEN email <> lower(email) AND email <> trim(email) THEN 'cả hai'
         WHEN email <> lower(email) THEN 'chữ hoa'
         ELSE 'khoảng trắng'
       END AS issue
FROM users
WHERE email <> lower(email) OR email <> trim(email)
ORDER BY id;
