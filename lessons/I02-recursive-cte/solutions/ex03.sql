-- db: shop_s
-- ordered
-- Giải thích: đi NGƯỢC lên cây: neo là danh mục của sản phẩm, đệ quy JOIN tới cha (c.id = t.parent_id) và ghép tên cha vào
--   ĐẦU chuỗi. Dòng cuối của mỗi sản phẩm là dòng đã tới gốc (parent_id IS NULL), lấy dòng đó.
-- Bẫy: ghép tên vào cuối chuỗi (ra thứ tự ngược 'Ốp lưng > … > Điện tử'); lấy mọi dòng thay vì chỉ dòng đã tới gốc.
WITH RECURSIVE up AS (
  SELECT p.id AS product_id, c.parent_id, c.name::text AS breadcrumb
  FROM products p
  JOIN categories c ON c.id = p.category_id
  WHERE p.id <= 5
  UNION ALL
  SELECT up.product_id, c.parent_id, c.name || ' > ' || up.breadcrumb
  FROM up
  JOIN categories c ON c.id = up.parent_id
)
SELECT product_id, breadcrumb
FROM up
WHERE parent_id IS NULL
ORDER BY product_id;
