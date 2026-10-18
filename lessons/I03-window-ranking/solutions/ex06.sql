-- db: shop_s
-- ordered
-- Giải thích: đánh số thứ tự đơn của mỗi khách trên TOÀN BỘ lịch sử (bỏ đơn cancelled) TRƯỚC, rồi mới lọc năm 2026.
--   Thứ tự logic: FROM → WHERE → GROUP BY → window → SELECT → ORDER BY. Nếu lọc 2026 ở cùng tầng với window, đơn đầu tiên
--   của năm 2026 bị đánh số 1 dù khách đã mua từ 2024.
-- Bẫy: WHERE created_at >= 2026 cùng tầng với row_number() → "đơn đầu" bị đếm quá nhiều.
WITH numbered AS (
  SELECT created_at, total_amount,
         row_number() OVER (PARTITION BY user_id ORDER BY created_at, id) AS nth
  FROM orders
  WHERE status <> 'cancelled'
)
SELECT to_char(date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM') AS thang,
       sum(total_amount) FILTER (WHERE nth = 1) AS first_order_revenue,
       sum(total_amount) FILTER (WHERE nth > 1) AS repeat_revenue
FROM numbered
WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
GROUP BY 1
ORDER BY 1;
