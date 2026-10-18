# Bench: i04-running-total-daily

- Ngày: 2026-10-17 10:40:16
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i04_cum_daily.sql`
- Runs mỗi mức: 1
- Tham số phiên: mặc định

```sql
SELECT max(cum) FROM (SELECT sum(sum(total_amount)) OVER (ORDER BY (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date) AS cum FROM orders GROUP BY (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date) t;

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 14.05 (14.05–14.05) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 123 / 0 | 0.0 |
| m | 1,000,000 | 724.06 (724.06–724.06) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 755 / 11177 | 39.9 |
| l | 10,000,000 | 11620.80 (11620.80–11620.80) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 819 / 118478 | 796.5 |
