-- db: lab
-- mode: check
-- reset
-- Giải thích: thứ tự bắt buộc là xóa trùng → chuẩn hóa → rồi mới thêm ràng buộc. Thêm trước thì CREATE UNIQUE INDEX lỗi
--   vì dữ liệu cũ đang trùng. Unique index trên BIỂU THỨC lower(trim(email)) chặn được cả bản ghi mới chưa chuẩn hóa.
--   Cách khác cũng đạt: CHECK (email = lower(trim(email))) + UNIQUE (email), ép ứng dụng tự chuẩn hóa trước khi ghi.
-- Bẫy: giữ id nhỏ nhất thay vì created_at sớm nhất (nhóm binh: id 4 tạo trước id 3); UNIQUE (email) thường không chặn ' AN@x.vn '.
DELETE FROM f09.legacy_users s USING f09.legacy_users k
WHERE lower(trim(k.email)) = lower(trim(s.email))
  AND (k.created_at, k.id) < (s.created_at, s.id);
UPDATE f09.legacy_users SET email = lower(trim(email)) WHERE email <> lower(trim(email));
CREATE UNIQUE INDEX legacy_users_email_norm_key ON f09.legacy_users (lower(trim(email)));
