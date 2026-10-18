# Bench: i03-latest-distinct-on

- Ngày: 2026-10-17 10:32:19
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i03_don.sql`
- Runs mỗi mức: 1
- Tham số phiên: mặc định

```sql
SELECT count(*), sum(total_amount) FROM (SELECT DISTINCT ON (user_id) user_id, total_amount FROM orders ORDER BY user_id, created_at DESC, id DESC) t;

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 4.94 (4.94–4.94) | Aggregate › Unique › Sort › Seq Scan [orders] | 1 | 126 / 0 | 0.0 |
| m | 1,000,000 | 695.92 (695.92–695.92) | Aggregate › Unique › Sort › Seq Scan [orders] | 1 | 947 / 10988 | 161.1 |
| l | 10,000,185 | 8194.97 (8194.97–8194.97) | Aggregate › Unique › Sort › Seq Scan [orders] | 1 | 1323 / 117977 | 1609.9 |
