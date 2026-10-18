CREATE MATERIALIZED VIEW i09.mv_daily_revenue AS
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, count(*) AS n_orders, sum(total) AS revenue
FROM i09.orders WHERE status <> 'cancelled' GROUP BY 1;
