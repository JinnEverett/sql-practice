SELECT split_part(email, '@', 2) AS domain, count(*) AS n_users,
       round(100.0 * count(*) / (SELECT count(*) FROM users), 1) AS pct
FROM users GROUP BY 1 ORDER BY n_users DESC, domain;
