-- db: shop_s
-- ordered
-- expect-rows: 9
-- Giải thích: giá trị đơn lệch phải (khách "whale" mua đơn rất lớn), nên trung bình bị kéo lên và KHÔNG đại diện cho đơn điển hình. Báo cáo đúng dùng percentile.
--   percentile_cont(p) WITHIN GROUP (ORDER BY x) nội suy giữa hai giá trị kề nhau; percentile_disc chọn một giá trị có thật trong dữ liệu.
--   Ở đây dùng _cont cho cả p50, p90, p99. Làm tròn ra đồng nguyên. Tháng theo giờ Việt Nam; chỉ tính đơn không bị hủy/hoàn (đã bán thành công).
-- Bẫy: avg() thay median; percentile_disc cho số khác nhẹ so với _cont; quên cast ::numeric khi làm tròn; sắp xếp theo tên tháng dạng text.
SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS month,
       count(*) AS n_orders,
       round(avg(total_amount)) AS avg_amount,
       round(percentile_cont(0.5)  WITHIN GROUP (ORDER BY total_amount)::numeric) AS p50,
       round(percentile_cont(0.9)  WITHIN GROUP (ORDER BY total_amount)::numeric) AS p90,
       round(percentile_cont(0.99) WITHIN GROUP (ORDER BY total_amount)::numeric) AS p99
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
  AND created_at >= '2026-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
GROUP BY 1
ORDER BY 1;
