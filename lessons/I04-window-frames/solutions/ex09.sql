-- db: lab
-- reset
-- ordered
-- Giải thích: số dư lũy kế = sum(qty) OVER (PARTITION BY product_id ORDER BY moved_at, id ROWS UNBOUNDED PRECEDING).
--   Phải có id trong ORDER BY và frame ROWS: hai dòng cùng moved_at (sản phẩm 4) nếu để RANGE mặc định sẽ được cộng CÙNG LÚC
--   (peers) → số dư nhảy thẳng 8 + (−9) = −1 ở cả hai dòng, không thấy thứ tự thật.
--   Lần âm ĐẦU TIÊN mỗi sản phẩm: lọc balance < 0 rồi lấy dòng sớm nhất bằng row_number (hoặc DISTINCT ON).
-- Bẫy: frame mặc định với giá trị ORDER BY trùng; lấy mọi dòng âm thay vì dòng đầu tiên.
WITH b AS (
  SELECT id, product_id, moved_at, qty,
         sum(qty) OVER (PARTITION BY product_id ORDER BY moved_at, id ROWS UNBOUNDED PRECEDING) AS balance
  FROM i04.stock_moves
), neg AS (
  SELECT *, row_number() OVER (PARTITION BY product_id ORDER BY moved_at, id) AS k
  FROM b
  WHERE balance < 0
)
SELECT product_id, id AS move_id, moved_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS moved_at_vn, qty, balance
FROM neg
WHERE k = 1
ORDER BY product_id;
