-- sai: row-value coi cả ba cột cùng chiều tăng
SELECT id, status, created_at FROM r02.tickets
WHERE (status, created_at, id) > ('open', '2026-02-01 02:00+00', 12)
ORDER BY status, created_at DESC, id DESC LIMIT 6;
