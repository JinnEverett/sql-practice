-- db: shop_s
SELECT count(*) AS total_orders, count(discount_code) AS orders_with_code,
       round(count(discount_code) * 100.0 / count(*), 2) AS pct_with_code
FROM orders;
