-- db: shop_s
-- ordered
-- expect-rows: 31
-- Giải thích: cohort = nhóm khách có cùng tháng mua đầu tiên. Bước 1: tháng mua đầu của mỗi khách (min của created_at trên đơn không bị hủy);
--   bước 2: đổi sang tháng THEO GIỜ VIỆT NAM rồi đếm khách theo tháng. Đổi múi giờ sau khi lấy min (đơn đầu tiên không đổi), trước khi cắt tháng.
-- Bẫy: date_trunc('month', created_at) không có AT TIME ZONE cắt tháng theo UTC (đơn đêm cuối tháng giờ VN rơi sang tháng khác); đếm cả đơn cancelled.
SELECT date_trunc('month', first_order AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS cohort_month,
       count(*) AS cohort_size
FROM (SELECT user_id, min(created_at) AS first_order
      FROM orders WHERE status <> 'cancelled' GROUP BY user_id) f
GROUP BY 1
ORDER BY 1;
