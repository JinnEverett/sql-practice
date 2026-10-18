-- db: lab
-- reset
-- ordered
-- expect-rows: 7
-- Giải thích: feed có 5 bài cùng created_at. Cursor (phút 20, id 103) nằm GIỮA một nhóm trùng. Row-value (created_at, id) < (…) xử lý đúng:
--   lấy tiếp id 102, 101 của nhóm cũ rồi sang nhóm kế. Điều kiện chỉ theo created_at làm mất 102 và 101 (hoặc lặp lại 104, 105).
-- Bẫy: created_at < ts (mất dòng), created_at <= ts (lặp dòng), quên id trong ORDER BY.
SELECT id, created_at, title
FROM r02.feed
WHERE (created_at, id) < ('2026-01-01 00:20+00', 103)
ORDER BY created_at DESC, id DESC
LIMIT 7;
