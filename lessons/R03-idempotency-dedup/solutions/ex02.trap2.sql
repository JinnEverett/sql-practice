-- sai: giữ dòng CŨ nhất (ORDER BY updated_at ASC) thay vì mới nhất
DELETE FROM r03.contacts WHERE id IN (
  SELECT id FROM (SELECT id, row_number() OVER (PARTITION BY lower(btrim(email)) ORDER BY updated_at, id) rn FROM r03.contacts) t WHERE rn > 1);
