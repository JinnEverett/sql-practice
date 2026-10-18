-- sai: view không lọc deleted_at; unique partial đúng
CREATE VIEW r05.active_accounts AS SELECT id, email, name FROM r05.accounts;
CREATE UNIQUE INDEX accounts_email_active_uq ON r05.accounts (lower(email)) WHERE deleted_at IS NULL;
