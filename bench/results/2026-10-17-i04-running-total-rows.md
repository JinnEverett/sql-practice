# Bench: i04-running-total-rows

- Ngày: 2026-10-17 10:39:23
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i04_cum_rows.sql`
- Runs mỗi mức: 1
- Tham số phiên: mặc định

```sql
SELECT max(cum) FROM (SELECT sum(total_amount) OVER (ORDER BY created_at, id ROWS UNBOUNDED PRECEDING) AS cum FROM orders) t;

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 7.60 (7.60–7.60) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 126 / 0 | 0.0 |
| m | 1,000,000 | 1273.47 (1273.47–1273.47) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 194 / 11741 | 125.7 |
| l | 10,000,000 | 9021.52 (9021.52–9021.52) | Aggregate › WindowAgg › Sort › Seq Scan [orders] | 1 | 194 / 119106 | 1255.3 |
