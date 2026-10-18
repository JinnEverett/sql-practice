-- db: lab
-- ordered
SELECT 'chỉ A' AS nguon, sku, warehouse, qty FROM (SELECT * FROM f07.stock_a EXCEPT ALL SELECT * FROM f07.stock_b) a
UNION ALL
SELECT 'chỉ B', sku, warehouse, qty FROM (SELECT * FROM f07.stock_b EXCEPT ALL SELECT * FROM f07.stock_a) b
ORDER BY nguon, sku, warehouse;
