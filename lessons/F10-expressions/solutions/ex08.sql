-- db: shop_s
-- ordered
-- Giải thích: so "tháng-ngày" bằng to_char(birth_date, 'MM-DD'): chuỗi 'MM-DD' có độ dài cố định nên so sánh chuỗi = so sánh ngày.
--   Cách này không bao giờ lỗi, kể cả người sinh 29/02. Tuổi mới = 2026 − năm sinh (vì sinh nhật rơi vào tuần đang xét).
-- Bẫy: make_date(2026, tháng, ngày) cho mọi người → lỗi "date field value out of range" với người sinh 29/02 (năm 2026 không nhuận);
--   extract(doy) lệch 1 ngày giữa năm nhuận và năm thường.
SELECT id, full_name, birth_date,
       2026 - extract(year FROM birth_date)::int AS tuoi_moi
FROM users
WHERE deleted_at IS NULL
  AND to_char(birth_date, 'MM-DD') BETWEEN '10-19' AND '10-25'
ORDER BY to_char(birth_date, 'MM-DD'), id;
