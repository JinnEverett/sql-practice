-- sai: lọc DELETE trước khi chọn sự kiện cuối → sản phẩm 2 (đã xóa tháng 3) hiện lại với dữ liệu cũ
SELECT row_id AS product_id, new_row->>'name' AS name, (new_row->>'price')::numeric AS price
FROM (
  SELECT DISTINCT ON (row_id) row_id, op, new_row FROM r05.audit_log
  WHERE table_name = 'products' AND changed_at <= '2026-04-15 12:00+00' AND op <> 'DELETE'
  ORDER BY row_id, changed_at DESC, id DESC) t
ORDER BY product_id;
