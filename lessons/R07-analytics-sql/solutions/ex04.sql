-- db: lab
-- reset
-- ordered
-- expect-rows: 8
-- Giải thích: gaps & islands: một "đảo" (island) là chuỗi ngày liên tiếp. Mẹo kinh điển: trong mỗi đảo, (ngày − số thứ tự dòng) là HẰNG SỐ.
--   Các bước: (1) khử trùng theo (user, ngày) vì user 3 đăng nhập hai lần trong một ngày; (2) row_number() theo user, thứ tự ngày;
--   (3) island = ngày − row_number (ngày liên tiếp cho cùng một giá trị); (4) GROUP BY (user, island) lấy min/max ngày và số ngày.
--   Ngày tính theo giờ Việt Nam: lần đăng nhập 23:30 UTC ngày 03/03 là ngày 04/03 ở VN.
-- Bẫy: quên khử trùng → row_number lệch, đảo bị tách đôi sai; quên đổi múi giờ; so sánh ngày với số thứ tự cần ép date − int.
WITH d AS (
  SELECT DISTINCT user_id, (login_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day FROM r07.logins
), g AS (
  SELECT user_id, day, day - (row_number() OVER (PARTITION BY user_id ORDER BY day))::int AS island FROM d
)
SELECT user_id, min(day) AS streak_start, max(day) AS streak_end, count(*) AS days
FROM g
GROUP BY user_id, island
ORDER BY user_id, streak_start;
