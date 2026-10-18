DELETE FROM f09.legacy_users s USING f09.legacy_users k
WHERE lower(trim(k.email)) = lower(trim(s.email)) AND (k.created_at, k.id) < (s.created_at, s.id);
UPDATE f09.legacy_users SET email = lower(trim(email));
ALTER TABLE f09.legacy_users ADD UNIQUE (email);
