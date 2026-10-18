SELECT id, name, slug, trim(BOTH '-' FROM regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g')) AS generated
FROM categories WHERE slug <> trim(BOTH '-' FROM regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g')) ORDER BY id;
