-- db: shop_s
-- ordered
-- expect-rows: 42
-- Giải thích: breadcrumb = đường đi từ gốc xuống nút. Đệ quy từ gốc xuống, nối tên bằng ' > ' khi đi sâu; mỗi nút xuất hiện đúng một lần
--   nên kết quả có 42 dòng. (Đi từ nút lên gốc cũng được nhưng phải đảo thứ tự khi nối.)
-- Bẫy: nối bằng || với NULL ở gốc (dùng neo = name, không phải coalesce(parent_path, '') || ' > ' || name); thiếu depth nên không phân biệt tầng.
WITH RECURSIVE t AS (
  SELECT id, name::text AS breadcrumb, 0 AS depth FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, t.breadcrumb || ' > ' || c.name, t.depth + 1 FROM categories c JOIN t ON c.parent_id = t.id
)
SELECT id, breadcrumb, depth FROM t ORDER BY id;
