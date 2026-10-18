-- cách khác: window function (I03) + CHECK ép chuẩn hóa + UNIQUE thường
DELETE FROM f09.legacy_users WHERE id IN (
  SELECT id FROM (SELECT id, row_number() OVER (PARTITION BY lower(trim(email)) ORDER BY created_at, id) AS rn
                  FROM f09.legacy_users) t WHERE rn > 1);
UPDATE f09.legacy_users SET email = lower(trim(email));
ALTER TABLE f09.legacy_users ADD CHECK (email = lower(trim(email))), ADD UNIQUE (email);
