# Bench: p02-user-lookup-noindex

- Ngày: 2026-10-18 02:32:57
- Query: `/tmp/bq/p02-user-lookup.sql`
- Runs mỗi mức: 5
- Tham số phiên: mặc định

```sql
SELECT id FROM orders WHERE user_id = 77;

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| xs | 100 | 0.01 (0.01–0.03) | Seq Scan [orders] | 0 | 2 / 0 | 0.0 |
| s | 10,000 | 0.71 (0.69–1.09) | Seq Scan [orders] | 22 | 120 / 0 | 0.0 |
| m | 1,000,000 | 23.22 (22.68–28.00) | Gather › Seq Scan [orders] | 411 | 11929 / 0 | 0.0 |
