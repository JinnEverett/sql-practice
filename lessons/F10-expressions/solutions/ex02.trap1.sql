SELECT CASE WHEN city IN ('TP. Hồ Chí Minh', 'TP.HCM', 'HCM', 'Ho Chi Minh') THEN 'TP. Hồ Chí Minh' ELSE city END AS city_norm,
       count(*) AS n_users
FROM users WHERE country = 'VN' GROUP BY 1 ORDER BY n_users DESC, city_norm;
