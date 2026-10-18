UPDATE f08.products p
SET stock = f.qty, price = COALESCE(f.price, p.price), updated_at = now()
FROM (SELECT DISTINCT ON (sku) sku, qty, price FROM f08.stock_feed ORDER BY sku, received_at DESC) f
WHERE f.sku = p.sku;
