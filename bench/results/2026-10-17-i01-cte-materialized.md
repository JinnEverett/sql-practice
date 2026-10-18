# Bench: i01-cte-materialized

- Ngày: 2026-10-17 09:11:02
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i01_mat.sql`
- Runs mỗi mức: 3
- Tham số phiên: mặc định

```sql
WITH o AS MATERIALIZED (SELECT * FROM orders) SELECT * FROM o WHERE id = 5000;

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 1.45 (1.38–1.65) | CTE Scan › Seq Scan [orders] | 1 | 120 / 0 | 0.0 |
| m | 1,000,000 | 222.71 (203.61–227.66) | CTE Scan › Seq Scan [orders] | 1 | 564 / 11365 | 75.3 |
| l | 10,000,185 | 6962.35 (6550.00–10141.62) | CTE Scan › Seq Scan [orders] | 1 | 940 / 118354 | 752.6 |
