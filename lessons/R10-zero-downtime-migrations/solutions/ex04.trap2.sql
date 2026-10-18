-- sai: dựng bằng CREATE UNIQUE INDEX thường (khóa SHARE chặn mọi INSERT/UPDATE/DELETE trong lúc dựng)
DELETE FROM r10.users u USING r10.users k WHERE u.email = k.email AND (u.updated_at, u.id) < (k.updated_at, k.id);
DROP INDEX r10.users_email_uq;
CREATE UNIQUE INDEX users_email_uq ON r10.users (email);
