CREATE INDEX ON users (email);
CREATE INDEX ON orders (user_id);
-- query
SELECT o.id FROM orders o WHERE o.id = 123456
UNION ALL
SELECT o.id FROM orders o JOIN users u ON u.id = o.user_id WHERE u.email = 'nhung.le500@outlook.com' AND o.id <> 123456;
