-- db: lab
-- mode: state
-- Giải thích: "cùng một người" = cùng email sau khi chuẩn hóa lower(btrim(email)). Mỗi nhóm giữ MỘT dòng: updated_at mới nhất, trùng thì id lớn nhất.
--   row_number() OVER (PARTITION BY lower(btrim(email)) ORDER BY updated_at DESC, id DESC) = 1 là dòng giữ lại; xóa các dòng còn lại.
-- Bẫy: PARTITION BY email thô → không thấy trùng; thiếu tie-breaker id → hai dòng cùng updated_at, kết quả không xác định; DELETE USING tự nối với điều kiện < thay vì = làm xóa nhầm.
DELETE FROM r03.contacts
WHERE id IN (
  SELECT id FROM (
    SELECT id, row_number() OVER (PARTITION BY lower(btrim(email)) ORDER BY updated_at DESC, id DESC) AS rn
    FROM r03.contacts) t
  WHERE rn > 1);
