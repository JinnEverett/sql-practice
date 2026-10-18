UPDATE f08.products p SET stock = f.qty, price = COALESCE(f.price, p.price), updated_at = now()
FROM f08.stock_feed f WHERE f.sku = p.sku;
