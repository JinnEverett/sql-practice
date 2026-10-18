-- db: shop_s
-- ordered
-- Giải thích: adjacency list (mỗi nút giữ parent_id) duyệt cây bằng recursive CTE: phần neo = các con trực tiếp của nút 2 (depth 1),
--   phần đệ quy nối tiếp con của các nút đã tìm thấy (depth + 1). Cây không có chu trình nên không cần chống vòng lặp; dữ liệu bẩn thì cần (I02).
-- Bẫy: neo là chính nút 2 (depth 0) sẽ trả thêm cả nút gốc; quên cột depth; dùng UNION thay UNION ALL (chậm hơn, không cần khi cây sạch).
WITH RECURSIVE sub AS (
  SELECT id, name, 1 AS depth FROM categories WHERE parent_id = 2
  UNION ALL
  SELECT c.id, c.name, s.depth + 1 FROM categories c JOIN sub s ON c.parent_id = s.id
)
SELECT id, name, depth FROM sub ORDER BY depth, id;
