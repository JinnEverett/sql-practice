-- sai: tháng theo UTC (đơn từ 0h–7h sáng ngày mùng 1 giờ VN bị tính vào tháng trước) và quên loại đơn hủy
SELECT date_trunc('month', o.created_at)::date AS month,
       sum(oi.unit_price * oi.quantity) AS revenue_at_purchase,
       sum(p.price * oi.quantity) AS revenue_at_current_price,
       sum(oi.unit_price * oi.quantity) - sum(p.price * oi.quantity) AS diff
FROM orders o JOIN order_items oi ON oi.order_id = o.id JOIN products p ON p.id = oi.product_id
WHERE o.created_at >= '2026-01-01 00:00+07' AND o.created_at < '2026-04-01 00:00+07'
GROUP BY 1 ORDER BY 1;
