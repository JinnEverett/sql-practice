-- db: lab
-- reset
-- ordered
-- expect-rows: 6
-- Giải thích: ORDER BY status ASC, created_at DESC, id DESC có hướng HỖN HỢP, nên so sánh row-value một chiều (a, b, c) > (…) không áp dụng được.
--   Mở rộng thành các nhánh theo từng cột đứng trước: status lớn hơn; hoặc status bằng và created_at nhỏ hơn; hoặc status, created_at bằng và id nhỏ hơn.
--   (Với kiểu số có thể đổi dấu để đưa về cùng chiều; text/timestamptz thì viết tường minh như dưới đây.)
-- Bẫy: (status, created_at, id) > ('open', ts, 12) coi cả 3 cột cùng tăng → sai thứ tự ở created_at và id.
SELECT id, status, created_at
FROM r02.tickets
WHERE status > 'open'
   OR (status = 'open' AND created_at < '2026-02-01 02:00+00')
   OR (status = 'open' AND created_at = '2026-02-01 02:00+00' AND id < 12)
ORDER BY status, created_at DESC, id DESC
LIMIT 6;
