-- db: shop_s
-- ordered
SELECT id, stock,
       stock / 12        AS full_boxes,
       stock % 12        AS remainder,
       (stock + 11) / 12 AS boxes_needed
FROM products WHERE id <= 10 ORDER BY id;
