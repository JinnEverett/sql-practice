update f08.products p set stock = sf.qty, price = coalesce(sf.price, p.price), updated_at = now() from (select distinct on(sku) 
sku,name, qty, price from f08.stock_feed order by sku, received_at desc) sf where sf.sku = p.sku;
