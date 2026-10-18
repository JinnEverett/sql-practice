-- db: shop_s
-- ordered
-- Giải thích: tên người Việt = từ CUỐI của họ tên. substring(s from '(\S+)$') lấy nhóm bắt (…) khớp chuỗi ký tự không phải khoảng
--   trắng ở cuối. trim() trước để khoảng trắng cuối không làm hỏng mẫu. full_name NULL bị loại.
-- Bẫy: split_part(full_name, ' ', 3) giả định luôn có 3 từ (tên 2 hoặc 4 từ sẽ sai); split_part(…, ' ', 1) là HỌ, không phải tên.
SELECT substring(trim(full_name) FROM '(\S+)$') AS ten, count(*) AS n_users
FROM users
WHERE full_name IS NOT NULL
GROUP BY 1
ORDER BY n_users DESC, ten
LIMIT 10;
