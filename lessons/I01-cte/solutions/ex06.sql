-- db: lab
-- mode: state
-- Giải thích: data-modifying CTE: DELETE … RETURNING * trả về các dòng vừa xóa, INSERT bên ngoài chép chúng sang bảng archive.
--   Cả hai thao tác nằm trong MỘT câu lệnh → cùng một snapshot, hoặc cùng thành công hoặc cùng thất bại: không thể "xóa mà
--   chưa kịp chép" hay "chép mà xóa sót". archived_at tự nhận DEFAULT now().
-- Bẫy: mốc '2026-07-01' không múi giờ (hiểu là UTC, tức 07:00 giờ VN) → chuyển nhầm đơn 4; dùng <= cũng chuyển nhầm đơn 4.
WITH moved AS (
  DELETE FROM i01.orders
  WHERE status = 'cancelled' AND created_at < '2026-07-01 00:00+07'
  RETURNING id, user_id, status, created_at, total
)
INSERT INTO i01.orders_archive (id, user_id, status, created_at, total)
SELECT id, user_id, status, created_at, total FROM moved;
