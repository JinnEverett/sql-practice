-- sai: percentile_disc thay vì percentile_cont
SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS month, count(*) AS n_orders, round(avg(total_amount)) AS avg_amount,
       round(percentile_disc(0.5)  WITHIN GROUP (ORDER BY total_amount)::numeric) AS p50,
       round(percentile_disc(0.9)  WITHIN GROUP (ORDER BY total_amount)::numeric) AS p90,
       round(percentile_disc(0.99) WITHIN GROUP (ORDER BY total_amount)::numeric) AS p99
FROM orders WHERE status NOT IN ('cancelled', 'refunded') AND created_at >= '2026-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
GROUP BY 1 ORDER BY 1;
