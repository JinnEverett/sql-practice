insert into f08.products (sku, name, price, stock) 
select distinct on(sku) sku, name, price, qty from f08.stock_feed sf where not exists (select 1 from f08.products p where p.sku = sf.sku) order by sf.sku, sf.received_at desc;
