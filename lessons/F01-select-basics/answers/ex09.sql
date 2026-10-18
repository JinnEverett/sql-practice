select id, user_id, total_amount, created_at from orders
  where created_at >= '09-01-2026' and created_at < '10-01-2026' and total_amount > 2000000 and status = 'pending'
  order by total_amount desc, created_at asc
;
-- ⏳ CHƯA ĐẠT (2026-10-08) — người học tạm gác, quay lại sau. Còn thiếu:
--   1. total_amount > 2000000  → đề: "từ 2 triệu trở lên"
--   2. '09-01-2026' kiểu MDY   → phụ thuộc DateStyle
--   3. mốc không có múi giờ    → đề: tính theo UTC
--   4. ORDER BY thiếu id làm tiêu chí phụ

-- 🔑 ĐÁP ÁN (người học xin đáp án, 2026-10-08). Bài này không tính điểm.
-- select id, user_id, total_amount, created_at
-- from orders
-- where status = 'pending'
--   and created_at >= '2026-09-01 00:00+00'
--   and created_at <  '2026-10-01 00:00+00'
--   and total_amount >= 2000000
-- order by total_amount desc, created_at asc, id asc;
