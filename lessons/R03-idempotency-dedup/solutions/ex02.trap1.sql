-- sai: PARTITION BY email thô → không nhóm được 'an@x.vn' với 'AN@x.vn' → không xóa gì
DELETE FROM r03.contacts WHERE id IN (
  SELECT id FROM (SELECT id, row_number() OVER (PARTITION BY email ORDER BY updated_at DESC, id DESC) rn FROM r03.contacts) t WHERE rn > 1);
