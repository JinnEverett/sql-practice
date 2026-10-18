-- db: lab
-- reset
-- ordered
-- Giải thích: neo = các linh kiện trực tiếp của 'Laptop' với số lượng = qty × 10 (10 máy). Đệ quy: số lượng của con = số lượng
--   của cha (đã nhân dồn) × qty trong định mức. Chỉ giữ LÁ (linh kiện không có trong cột parent), rồi cộng theo linh kiện vì
--   một linh kiện (Ốc vít) xuất hiện ở nhiều nhánh.
-- Bẫy: không nhân dồn số lượng của cha (Ốc vít ra 220 thay vì 240); tính cả linh kiện trung gian (Mainboard, Quạt…) vào kết quả.
WITH RECURSIVE need AS (
  SELECT child AS part, qty * 10 AS total_qty
  FROM i02.bom
  WHERE parent = 'Laptop'
  UNION ALL
  SELECT b.child, need.total_qty * b.qty
  FROM need
  JOIN i02.bom b ON b.parent = need.part
)
SELECT part, sum(total_qty) AS total_qty
FROM need
WHERE NOT EXISTS (SELECT 1 FROM i02.bom b WHERE b.parent = need.part)
GROUP BY part
ORDER BY part;
