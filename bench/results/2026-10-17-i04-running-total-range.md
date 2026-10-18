# Bench: i04-running-total-range

- Ngày: 2026-10-17 10:39:10
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i04_cum.sql`
- Runs mỗi mức: 1
- Tham số phiên: mặc định

```sql
SELECT max(cum) FROM (SELECT sum(total_amount) OVER (ORDER BY created_at, id) AS cum FROM orders) t;

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 7.32 (7.32–7.32) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 126 / 0 | 0.0 |
| m | 1,000,000 | 936.91 (936.91–936.91) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 6 / 11929 | 125.7 |
| l | 10,000,000 | 10037.13 (10037.13–10037.13) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 6 / 119294 | 1255.3 |
