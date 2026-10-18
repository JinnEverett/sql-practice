-- db: lab
-- reset
-- ordered
-- Giải thích: CTE đệ quy sinh MỌI cặp (sếp, cấp dưới gián tiếp/trực tiếp): neo = các cặp trực tiếp (manager_id, id);
--   đệ quy: cấp dưới của cấp dưới vẫn thuộc sếp ban đầu (giữ boss_id). Rồi đếm theo boss_id; n_direct đếm riêng.
-- Bẫy: chỉ đếm trực tiếp; đếm cả bản thân sếp; quên người không có cấp dưới phải bị loại (đề chỉ lấy người có cấp dưới).
WITH RECURSIVE sub AS (
  SELECT manager_id AS boss_id, id AS emp_id
  FROM i02.employees
  WHERE manager_id IS NOT NULL
  UNION ALL
  SELECT sub.boss_id, e.id
  FROM sub
  JOIN i02.employees e ON e.manager_id = sub.emp_id
)
SELECT b.id, b.full_name,
       (SELECT count(*) FROM i02.employees d WHERE d.manager_id = b.id) AS n_direct,
       count(*) AS n_total
FROM sub
JOIN i02.employees b ON b.id = sub.boss_id
GROUP BY b.id, b.full_name
ORDER BY n_total DESC, b.id;
