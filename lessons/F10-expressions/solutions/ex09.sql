-- db: shop_s
-- ordered
-- Giải thích: tầng trong cùng gom theo khách (chỉ đơn delivered, chỉ khách chưa bị xóa): ngày mua gần nhất, số đơn, tổng tiền.
--   recency = số NGÀY (giờ VN) từ ngày mua gần nhất tới mốc 2026-10-01; phép trừ date − date ra số nguyên.
--   Tầng giữa gán nhãn bằng CASE theo đúng THỨ TỰ ưu tiên của đề: nhánh đúng đầu tiên thắng, nên VIP phải đứng trước Trung thành.
--   Tầng ngoài đếm theo nhãn và sắp theo thứ tự nghiệp vụ bằng array_position.
-- Bẫy: đảo thứ tự nhánh (khách VIP mua nhiều bị xếp vào Trung thành); tính recency bằng now() thay vì mốc cố định;
--   lấy ngày theo UTC.
SELECT segment, count(*) AS n_users, round(avg(monetary)) AS avg_monetary
FROM (
  SELECT CASE
           WHEN monetary >= 50000000 AND recency_days <= 90 THEN 'VIP'
           WHEN frequency >= 5 THEN 'Trung thành'
           WHEN recency_days > 180 THEN 'Ngủ đông'
           ELSE 'Thường'
         END AS segment,
         monetary
  FROM (
    SELECT o.user_id,
           date '2026-10-01' - max((o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date) AS recency_days,
           count(*) AS frequency,
           sum(o.total_amount) AS monetary
    FROM orders o
    JOIN users u ON u.id = o.user_id
    WHERE o.status = 'delivered' AND u.deleted_at IS NULL
    GROUP BY o.user_id
  ) c
) s
GROUP BY segment
ORDER BY array_position(ARRAY['VIP', 'Trung thành', 'Ngủ đông', 'Thường'], segment);
