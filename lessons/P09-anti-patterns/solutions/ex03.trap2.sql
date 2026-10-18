-- query
SELECT id FROM orders WHERE id = 123456
UNION
SELECT o.id FROM users u JOIN orders o ON o.user_id = u.id WHERE u.email = 'nhung.le500@outlook.com';
