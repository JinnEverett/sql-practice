-- db: lab
-- mode: check
-- reset
-- Giải thích: soft delete = đánh dấu deleted_at thay vì DELETE. Hai việc phải làm đi kèm:
--   (1) view chỉ cho thấy dòng chưa xóa, để query của app không phải nhớ điều kiện `deleted_at IS NULL` ở mọi nơi;
--   (2) UNIQUE phải chỉ áp dụng cho dòng còn sống: unique index PARTIAL trên lower(email) WHERE deleted_at IS NULL,
--       nếu không email của tài khoản đã xóa chặn mãi việc đăng ký lại.
-- Bẫy: UNIQUE (email) thường → không đăng ký lại được; quên lower() → 'A@X.VN' và 'a@x.vn' cùng tồn tại; view không lọc → dữ liệu "đã xóa" vẫn lộ.
CREATE VIEW r05.active_accounts AS
  SELECT id, email, name FROM r05.accounts WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX accounts_email_active_uq ON r05.accounts (lower(email)) WHERE deleted_at IS NULL;
