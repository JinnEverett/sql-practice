-- cách đúng khác: DELETE … USING tự nối, giữ bản "lớn nhất" theo (updated_at, id)
DELETE FROM r03.contacts a
USING r03.contacts b
WHERE lower(btrim(a.email)) = lower(btrim(b.email))
  AND (a.updated_at, a.id) < (b.updated_at, b.id);
