-- db: lab
-- mode: check
-- reset
-- Giải thích: job 1 đang bị session B khóa (FOR UPDATE, 4 giây). SKIP LOCKED bỏ qua dòng đang bị khóa và lấy dòng tiếp theo (job 2) ngay: nhiều worker lấy việc song song mà không chờ nhau.
--   FOR UPDATE trơn sẽ xếp hàng chờ B và cuối cùng lấy job 1 sau khi B commit (worker bị kẹt); NOWAIT báo lỗi thay vì chờ.
-- Bẫy: bỏ SKIP LOCKED (worker đứng chờ); NOWAIT (lỗi 55P03 → không lấy được việc nào); chọn bằng SELECT rồi UPDATE hai bước không khóa (hai worker lấy trùng).
UPDATE p08.jobs SET state = 'taken'
WHERE id = (SELECT id FROM p08.jobs WHERE state = 'new' ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED);
