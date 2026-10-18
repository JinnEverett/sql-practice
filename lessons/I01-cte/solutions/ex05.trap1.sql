SELECT v.product_id, p.name, count(*) AS n_views, count(c.id) AS n_carts, round(100.0 * count(c.id) / count(*), 1) AS cart_rate
FROM (SELECT id, (properties->>'product_id')::bigint AS product_id FROM events WHERE event_type = 'product_view') v
JOIN products p ON p.id = v.product_id
LEFT JOIN (SELECT id, (properties->>'product_id')::bigint AS product_id FROM events WHERE event_type = 'add_to_cart') c ON c.product_id = v.product_id
GROUP BY v.product_id, p.name HAVING count(*) >= 50 ORDER BY cart_rate, v.product_id LIMIT 10;
