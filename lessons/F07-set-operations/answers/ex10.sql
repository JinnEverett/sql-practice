select distinct 'chỉ A' as nguon, sku, warehouse, qty from(select sku, warehouse, qty from lab.f07.stock_a except all select sku, warehouse, qty from lab.f07.stock_b)
union all
select distinct 'chỉ B' as nguon, sku, warehouse, qty from(select sku, warehouse, qty from lab.f07.stock_b except all select sku, warehouse, qty from lab.f07.stock_a)
order by nguon, sku, warehouse;
