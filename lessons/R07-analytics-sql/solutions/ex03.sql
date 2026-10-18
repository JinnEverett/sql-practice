-- db: shop_s
-- ordered
-- expect-rows: 3
-- Giải thích: funnel THEO THỨ TỰ: một visitor chỉ tính ở bước 2 nếu add_to_cart xảy ra SAU lần xem sản phẩm đầu tiên của họ, ở bước 3 nếu checkout sau add_to_cart đó.
--   Định danh visitor = coalesce(user_id::text, anonymous_id) (khách chưa đăng nhập chỉ có anonymous_id). Mỗi bước dùng mốc thời gian của bước trước:
--   t1 = lần product_view đầu; t2 = add_to_cart đầu tiên sau t1; t3 = checkout đầu tiên sau t2. Visitor "đến" bước k nếu t_k không NULL.
-- Bẫy: đếm distinct visitor cho từng loại event độc lập (không có thứ tự) → bước sau có thể đông hơn bước trước; quên múi giờ khi lọc tháng 9; mẫu số bước 1 khác nhau giữa các cột.
WITH ev AS (
  SELECT coalesce(user_id::text, anonymous_id) AS visitor, event_type, created_at
  FROM events
  WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
), s1 AS (
  SELECT visitor, min(created_at) AS t1 FROM ev WHERE event_type = 'product_view' GROUP BY visitor
), s2 AS (
  SELECT s1.visitor, s1.t1, (SELECT min(e.created_at) FROM ev e WHERE e.visitor = s1.visitor AND e.event_type = 'add_to_cart' AND e.created_at > s1.t1) AS t2
  FROM s1
), s3 AS (
  SELECT s2.visitor, s2.t1, s2.t2, (SELECT min(e.created_at) FROM ev e WHERE e.visitor = s2.visitor AND e.event_type = 'checkout' AND e.created_at > s2.t2) AS t3
  FROM s2
), counts AS (
  SELECT count(*) AS n1, count(t2) AS n2, count(t3) AS n3 FROM s3
)
SELECT step, visitors, round(100.0 * visitors / n1, 1) AS pct_of_step1
FROM counts, LATERAL (VALUES (1, 'product_view', n1), (2, 'add_to_cart', n2), (3, 'checkout', n3)) v(ord, step, visitors)
ORDER BY ord;
