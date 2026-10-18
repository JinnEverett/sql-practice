-- sai: dữ liệu đã sửa đúng nhưng chỉ có UNIQUE (product_id, valid_from) → khoảng chồng vẫn chèn được
UPDATE r05.price_history_bad p SET valid_to = n.next_from
FROM (SELECT product_id, valid_from, lead(valid_from) OVER (PARTITION BY product_id ORDER BY valid_from) AS next_from FROM r05.price_history_bad) n
WHERE p.product_id = n.product_id AND p.valid_from = n.valid_from AND n.next_from < coalesce(p.valid_to, 'infinity');
