-- db: lab
-- mode: state
-- show-output
-- Giải thích: nhận theo lô: cùng cấu trúc, LIMIT 3. Mỗi lần nhận lô làm giảm số vòng truy vấn (round trip) và chi phí transaction,
--   nhưng lô to thì job cuối chờ lâu trong tay worker; nếu worker chết, cả lô treo cho tới khi bị reclaim (ex04).
--   Lưu ý: RETURNING không đảm bảo thứ tự theo ORDER BY của subquery; nếu cần xử lý theo ưu tiên, sắp xếp lại ở phía worker.
-- Bẫy: LIMIT đặt ở UPDATE không có trong Postgres (phải qua subquery); IN (subquery có LIMIT) mà thiếu SKIP LOCKED thì chờ khóa.
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id IN (SELECT id FROM r04.jobs
             WHERE status = 'queued' AND run_at <= now()
             ORDER BY priority DESC, run_at, id
             LIMIT 3
             FOR UPDATE SKIP LOCKED)
RETURNING id;
