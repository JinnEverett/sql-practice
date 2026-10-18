-- sai: sắp giảm rồi LIMIT → lấy 7 bài mới nhất của cả feed
SELECT id, created_at, title FROM r02.feed
WHERE (created_at, id) > ('2026-01-01 00:10+00', 52)
ORDER BY created_at DESC, id DESC LIMIT 7;
