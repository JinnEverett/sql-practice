SELECT status, count(*) AS est_rows, count(*) AS actual_rows FROM orders GROUP BY status ORDER BY status LIMIT 5;
