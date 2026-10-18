-- db: lab
-- reset
-- ordered
-- expect-rows: 2
-- Giải thích: dựng lại trạng thái tại thời điểm T từ nhật ký = với mỗi row_id lấy sự kiện MỚI NHẤT có changed_at <= T; nếu đó là DELETE thì bản ghi không tồn tại.
--   DISTINCT ON (row_id) ... ORDER BY row_id, changed_at DESC, id DESC chọn sự kiện cuối. Lọc table_name và changed_at TRƯỚC khi chọn;
--   lọc op <> 'DELETE' SAU khi chọn (nếu lọc trước, một bản INSERT cũ của sản phẩm đã xóa sẽ "sống lại").
-- Bẫy: bỏ điều kiện thời gian (trả trạng thái hiện tại); lọc DELETE trước DISTINCT ON làm sản phẩm 2 hiện lại; quên lọc table_name.
SELECT row_id AS product_id, new_row->>'name' AS name, (new_row->>'price')::numeric AS price
FROM (
  SELECT DISTINCT ON (row_id) row_id, op, new_row
  FROM r05.audit_log
  WHERE table_name = 'products' AND changed_at <= '2026-04-15 12:00+00'
  ORDER BY row_id, changed_at DESC, id DESC
) last_event
WHERE op <> 'DELETE'
ORDER BY product_id;
