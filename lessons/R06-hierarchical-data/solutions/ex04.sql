-- db: lab
-- mode: state
-- Giải thích: closure table lưu MỌI cặp (tổ tiên, hậu duệ) kèm khoảng cách, gồm cả (n, n, 0). Dựng bằng recursive CTE neo ở các cặp (n, n, 0):
--   mỗi bước nối hậu duệ hiện tại với các con của nó, giữ nguyên tổ tiên và tăng depth. Số dòng = tổng (độ sâu + 1) của mọi nút = 89 với cây này.
--   Đổi lại tốc độ truy vấn (một JOIN với index) là dung lượng O(N × độ sâu) và chi phí cập nhật khi di chuyển cây con.
-- Bẫy: quên cặp (n, n, 0) khiến "cây con của n" không chứa n; bắt đầu depth ở 1 cho cặp tự thân.
WITH RECURSIVE c AS (
  SELECT id AS ancestor, id AS descendant, 0 AS depth FROM r06.cat
  UNION ALL
  SELECT c.ancestor, k.id, c.depth + 1 FROM c JOIN r06.cat k ON k.parent_id = c.descendant
)
INSERT INTO r06.cat_closure (ancestor, descendant, depth) SELECT ancestor, descendant, depth FROM c;
