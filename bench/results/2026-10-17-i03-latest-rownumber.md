# Bench: i03-latest-rownumber

- Ngày: 2026-10-17 10:32:07
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i03_rn.sql`
- Runs mỗi mức: 1
- Tham số phiên: mặc định

```sql
SELECT count(*), sum(total_amount) FROM (SELECT user_id, total_amount, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) AS rn FROM orders) t WHERE rn = 1;

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 5.89 (5.89–5.89) | Aggregate › Subquery Scan › WindowAgg › Sort › Seq Scan [orders] | 1 | 126 / 0 | 0.0 |
| m | 1,000,000 | 983.07 (983.07–983.07) | Aggregate › Subquery Scan › WindowAgg › Sort › Seq Scan [orders] | 1 | 759 / 11176 | 156.2 |
| l | 10,000,185 | 7155.45 (7155.45–7155.45) | Aggregate › Subquery Scan › WindowAgg › Sort › Seq Scan [orders] | 1 | 1135 / 118165 | 1561.1 |
