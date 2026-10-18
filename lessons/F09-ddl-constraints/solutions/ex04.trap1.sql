DELETE FROM f09.legacy_users s USING f09.legacy_users k
WHERE lower(trim(k.email)) = lower(trim(s.email)) AND k.id < s.id;
UPDATE f09.legacy_users SET email = lower(trim(email));
CREATE UNIQUE INDEX ON f09.legacy_users (lower(trim(email)));
