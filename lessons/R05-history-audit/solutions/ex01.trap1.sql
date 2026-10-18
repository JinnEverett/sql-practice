-- sai: UNIQUE thường → email của tài khoản đã xóa vẫn chặn đăng ký lại; thiếu lower()
CREATE VIEW r05.active_accounts AS SELECT id, email, name FROM r05.accounts WHERE deleted_at IS NULL;
ALTER TABLE r05.accounts ADD CONSTRAINT accounts_email_uq UNIQUE (email);
