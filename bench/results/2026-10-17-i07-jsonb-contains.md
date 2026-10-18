# Bench: i07-jsonb-contains

- Ngày: 2026-10-17 10:55:40
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i07_contain.sql`
- Runs mỗi mức: 1
- Tham số phiên: mặc định

```sql
SELECT count(*) FROM events WHERE properties @> '{"utm_source": "tiktok"}';

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 5.59 (5.59–5.59) | Aggregate › Seq Scan [events] | 1 | 452 / 0 | 0.0 |
| m | 1,000,000 | 365.62 (365.62–365.62) | Aggregate › Gather › Seq Scan [events] | 1 | 0 / 45243 | 0.0 |
| l | 10,000,000 | 3726.67 (3726.67–3726.67) | Aggregate › Gather › Seq Scan [events] | 1 | 29539 / 422308 | 0.0 |
