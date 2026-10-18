INSERT INTO f08.products (sku, name, price, stock)
SELECT DISTINCT ON (f.sku) f.sku, f.name, f.price, f.qty
FROM f08.stock_feed f
WHERE NOT EXISTS (SELECT 1 FROM f08.products p WHERE p.sku = f.sku)
ORDER BY f.sku, f.received_at DESC;
