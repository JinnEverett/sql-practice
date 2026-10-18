-- sai: bỏ điều kiện thời gian → trả trạng thái hiện tại (giá 140, có thêm sản phẩm 4)
SELECT row_id AS product_id, new_row->>'name' AS name, (new_row->>'price')::numeric AS price
FROM (
  SELECT DISTINCT ON (row_id) row_id, op, new_row FROM r05.audit_log
  WHERE table_name = 'products'
  ORDER BY row_id, changed_at DESC, id DESC) t
WHERE op <> 'DELETE'
ORDER BY product_id;
