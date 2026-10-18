SELECT coalesce(attributes->>'color', '(không có)') AS color, count(*) AS n_products FROM products GROUP BY 1 ORDER BY n_products DESC, color;
