# Bench: i06-ilike-events

- Ngày: 2026-10-17 10:49:57
- Query: `C:/Users/jinne/AppData/Local/Temp/claude/D--Learning-Sql/1a973681-930f-4e55-ad1d-b4a99a3f161c/scratchpad/q/i06_ilike.sql`
- Runs mỗi mức: 1
- Tham số phiên: mặc định

```sql
SELECT count(*) FROM events WHERE event_type = 'search' AND properties->>'query' ILIKE '%thun%';

```

| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |
|---|---|---|---|---|---|---|
| s | 10,000 | 16.64 (16.64–16.64) | Aggregate › Seq Scan [events] | 1 | 452 / 0 | 0.0 |
| m | 1,000,000 | 1207.18 (1207.18–1207.18) | Aggregate › Gather › Seq Scan [events] | 1 | 0 / 45243 | 0.0 |
| l | 10,000,000 | 15646.82 (15646.82–15646.82) | Aggregate › Gather › Seq Scan [events] | 1 | 0 / 451847 | 0.0 |
