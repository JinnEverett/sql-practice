-- ordered
SELECT 'orders' AS t, id FROM i01.orders
UNION ALL
SELECT 'archive', id FROM i01.orders_archive
ORDER BY t, id;
