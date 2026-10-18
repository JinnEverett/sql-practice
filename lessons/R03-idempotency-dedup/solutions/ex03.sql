-- db: shop_s
-- ordered
-- Giải thích: users.email KHÔNG unique ở shop_*: cùng người đăng ký nhiều lần với email viết khác hoa/thường hoặc thừa khoảng trắng.
--   Chuẩn hóa lower(btrim(email)) rồi nhóm; HAVING count(*) > 1 chỉ giữ nhóm trùng. array_agg(id ORDER BY id) cho danh sách tài khoản.
-- Bẫy: GROUP BY email thô → 0 nhóm; lower() mà quên btrim() → bỏ sót các email có khoảng trắng; count(DISTINCT email) đếm nhầm.
SELECT lower(btrim(email)) AS norm_email, count(*) AS n_users, array_agg(id ORDER BY id) AS user_ids
FROM users
GROUP BY lower(btrim(email))
HAVING count(*) > 1
ORDER BY norm_email;
