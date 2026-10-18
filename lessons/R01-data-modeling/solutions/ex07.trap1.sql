-- sai: tính cả hai cột theo giá hiện tại → diff luôn 0, không thấy chỗ lệch
SELECT date_trunc('month', o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS month,
       sum(p.price * oi.quantity) AS revenue_at_purchase,
       sum(p.price * oi.quantity) AS revenue_at_current_price,
       0::numeric AS diff
FROM orders o JOIN order_items oi ON oi.order_id = o.id JOIN products p ON p.id = oi.product_id
WHERE o.status NOT IN ('cancelled', 'refunded') AND o.created_at >= '2026-01-01 00:00+07' AND o.created_at < '2026-04-01 00:00+07'
GROUP BY 1 ORDER BY 1;
