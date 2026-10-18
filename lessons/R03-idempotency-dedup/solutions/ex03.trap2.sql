-- sai: lower() nhưng quên btrim() → bỏ sót các cặp trùng do khoảng trắng
SELECT lower(email) AS norm_email, count(*) AS n_users, array_agg(id ORDER BY id) AS user_ids
FROM users GROUP BY lower(email) HAVING count(*) > 1 ORDER BY norm_email;
