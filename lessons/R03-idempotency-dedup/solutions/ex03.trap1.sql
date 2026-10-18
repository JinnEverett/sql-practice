-- sai: nhóm theo email thô
SELECT email AS norm_email, count(*) AS n_users, array_agg(id ORDER BY id) AS user_ids
FROM users GROUP BY email HAVING count(*) > 1 ORDER BY norm_email;
