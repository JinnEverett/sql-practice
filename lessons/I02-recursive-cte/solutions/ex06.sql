-- db: lab
-- reset
-- ordered
-- Giải thích: đi LÊN từ mọi nhân viên (giữ start_id), mỗi bước sang manager_id. Mảng path lưu các id đã đi qua để DỪNG khi
--   gặp lại một id (chống vòng lặp vô hạn). Nhân viên thuộc vòng ⇔ trên đường đi lên gặp lại CHÍNH MÌNH.
--   Tương đương dùng mệnh đề CYCLE của Postgres 14+: CYCLE id SET is_cycle USING path.
--   23 và 27 trỏ VÀO vòng nhưng không nằm trên vòng; 26 tự quản lý chính mình là vòng độ dài 1.
-- Bẫy: không có điều kiện dừng → "infinite recursion"/chạy mãi; coi mọi node chạm vòng (23, 27) là thuộc vòng.
WITH RECURSIVE walk AS (
  SELECT id AS start_id, manager_id AS next_id, ARRAY[id] AS path
  FROM i02.emp_import
  UNION ALL
  SELECT w.start_id, e.manager_id, w.path || e.id
  FROM walk w
  JOIN i02.emp_import e ON e.id = w.next_id
  WHERE NOT e.id = ANY (w.path)
)
SELECT DISTINCT start_id AS id
FROM walk
WHERE next_id = start_id
ORDER BY id;
