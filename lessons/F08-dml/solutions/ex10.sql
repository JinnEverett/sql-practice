-- db: lab
-- mode: state
-- show-output
-- Giải thích: Điều kiện status = 'pending' AND created_at < mốc có múi giờ +07 (nửa mở, đúng mốc không tính). RETURNING id, user_id.
-- Chạy lần 2 trả về 0 dòng: job IDEMPOTENT, vì điều kiện status = 'pending' tự loại các đơn đã hủy. Job định kỳ có thể bị chạy lặp (retry, 2 instance chạy chồng) nên phải an toàn khi chạy lại: không hủy lại, không gửi thông báo trùng.
-- Bẫy: Dùng <= hoặc literal không múi giờ ('2026-10-10' hiểu theo UTC = 07:00 giờ VN) → hủy nhầm đơn 7.
UPDATE f08.orders SET status = 'cancelled', cancelled_at = now()
WHERE status = 'pending' AND created_at < '2026-10-10 00:00:00+07' RETURNING id, user_id;
