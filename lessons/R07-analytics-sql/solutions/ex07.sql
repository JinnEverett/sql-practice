-- db: shop_s
-- ordered
-- expect-rows: 30
-- Giải thích: DAU/WAU cuốn chiếu. Số khách KHÁC NHAU trong cửa sổ 7 ngày không cộng được từ DAU từng ngày (một khách hoạt động 3 ngày bị đếm 3 lần),
--   và Postgres không cho count(DISTINCT …) OVER (…). Cách làm: lưới ngày (generate_series) JOIN LEFT với đơn có ngày nằm trong [d − 6, d],
--   rồi count(DISTINCT user_id) gom theo ngày d. DAU = count(DISTINCT user_id) FILTER (WHERE ngày đơn = d).
--   Ngày theo giờ Việt Nam. Hoạt động = có đơn không bị hủy.
-- Bẫy: sum(DAU) trên 7 ngày (đếm trùng); window RANGE/ROWS trên bảng đã gom theo ngày cho DAU cộng dồn; bỏ qua ngày không có đơn (generate_series giữ ngày đó với 0).
WITH o AS (
  SELECT DISTINCT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, user_id
  FROM orders
  WHERE status <> 'cancelled'
    AND created_at >= '2026-08-25 00:00+07' AND created_at < '2026-10-01 00:00+07'
), days AS (
  SELECT d::date AS day FROM generate_series('2026-09-01'::date, '2026-09-30', interval '1 day') d
)
SELECT days.day,
       count(DISTINCT o.user_id) FILTER (WHERE o.day = days.day) AS dau,
       count(DISTINCT o.user_id) AS wau
FROM days
LEFT JOIN o ON o.day BETWEEN days.day - 6 AND days.day
GROUP BY days.day
ORDER BY days.day;
