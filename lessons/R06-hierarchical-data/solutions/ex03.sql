-- db: lab
-- mode: state
-- Giải thích: ltree lưu đường đi dưới dạng nhãn nối bằng dấu chấm; ở đây nhãn là id nên '2.16.34' = Điện tử > Âm thanh > Tai nghe.
--   Dựng path cho cả cây một lần bằng recursive CTE: gốc có path = id, con có path = path cha || id. Phép || với ltree nối nhãn.
-- Bẫy: id::text::ltree cần ép hai bước (int → text → ltree); path cha || con khi con là int sẽ lỗi kiểu; chạy UPDATE không có điều kiện JOIN nên cập nhật mọi dòng bằng cùng một giá trị.
WITH RECURSIVE t AS (
  SELECT id, id::text::ltree AS p FROM r06.cat WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, t.p || c.id::text FROM r06.cat c JOIN t ON c.parent_id = t.id
)
UPDATE r06.cat c SET path = t.p FROM t WHERE t.id = c.id;
