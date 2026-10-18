-- sai: sửa dữ liệu nhưng giữ index invalid → CREATE INDEX cùng tên báo lỗi "already exists"
DELETE FROM r10.users u USING r10.users k WHERE u.email = k.email AND (u.updated_at, u.id) < (k.updated_at, k.id);
CREATE UNIQUE INDEX CONCURRENTLY users_email_uq ON r10.users (email);
