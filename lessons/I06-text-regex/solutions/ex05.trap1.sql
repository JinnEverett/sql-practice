SELECT split_part(full_name, ' ', 1) AS ten, count(*) AS n_users FROM users WHERE full_name IS NOT NULL GROUP BY 1 ORDER BY n_users DESC, ten LIMIT 10;
