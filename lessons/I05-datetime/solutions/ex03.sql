-- db: shop_s
-- ordered
-- Giải thích: AT TIME ZONE nhận tên múi giờ từ một CỘT, nên mỗi dòng đổi sang múi giờ của khách đó. Bảng ánh xạ quốc gia → múi giờ
--   viết bằng VALUES. Dùng tên vùng IANA ('Australia/Sydney') chứ không dùng offset cố định, vì Sydney và Los Angeles có giờ mùa hè (DST):
--   offset thay đổi theo ngày trong năm, tên vùng tự xử lý.
-- Bẫy: dùng '+10' cho Sydney (sai nửa năm do DST); lấy giờ theo VN cho mọi khách.
WITH tz (country, zone) AS (
  VALUES ('SG', 'Asia/Singapore'), ('KR', 'Asia/Seoul'), ('AU', 'Australia/Sydney'),
         ('TH', 'Asia/Bangkok'), ('JP', 'Asia/Tokyo'), ('US', 'America/Los_Angeles')
)
SELECT u.country,
       count(*) AS n_orders,
       count(*) FILTER (WHERE extract(hour FROM o.created_at AT TIME ZONE tz.zone) < 6) AS n_night_local,
       count(*) FILTER (WHERE extract(hour FROM o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') < 6) AS n_night_vn
FROM orders o
JOIN users u ON u.id = o.user_id
JOIN tz ON tz.country = u.country
GROUP BY u.country
ORDER BY u.country;
