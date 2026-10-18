SELECT coalesce(city, '(không rõ)') AS city_norm, count(*) AS n_users
FROM users WHERE country = 'VN' GROUP BY 1 ORDER BY n_users DESC, city_norm;
