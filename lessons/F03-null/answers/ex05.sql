select count(*) as total_orders, count(discount_code) as orders_with_code, round(( count(discount_code)*1.0/count(*))*100,2) as 
pct_with_code from orders;
