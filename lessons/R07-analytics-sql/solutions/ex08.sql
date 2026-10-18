-- db: shop_s
-- ordered
-- expect-rows: 1
-- Giải thích: tỉ lệ mua lại và thời gian tới đơn thứ hai. Xếp các đơn không bị hủy của mỗi khách theo thời gian (row_number), lấy đơn 1 và đơn 2;
--   chỉ khách có đơn thứ hai mới có "ngày tới lần mua thứ hai". Tính theo NGÀY LỊCH Việt Nam (chênh lệch hai ngày date − date là số nguyên).
--   Mẫu số của tỉ lệ là mọi khách đã mua ít nhất một lần, không phải số khách mua lại.
--   Trung vị = percentile_cont(0.5) trên số ngày; chỉ tính khách đã mua lại.
-- Bẫy: chia cho số khách mua lại (tỉ lệ 100%); lấy trung vị trên tất cả đơn thay vì khoảng cách đơn 1 → đơn 2; đếm đơn cancelled như một lần mua.
WITH ranked AS (
  SELECT user_id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day,
         row_number() OVER (PARTITION BY user_id ORDER BY created_at, id) AS rn
  FROM orders WHERE status <> 'cancelled'
), per_user AS (
  SELECT user_id,
         max(day) FILTER (WHERE rn = 1) AS first_day,
         max(day) FILTER (WHERE rn = 2) AS second_day
  FROM ranked WHERE rn <= 2 GROUP BY user_id
)
SELECT count(*) AS n_buyers,
       count(second_day) AS n_repeat,
       round(100.0 * count(second_day) / count(*), 1) AS repeat_rate_pct,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY second_day - first_day)::numeric, 1) AS median_days_to_second
FROM per_user;
