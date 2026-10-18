CREATE INDEX ON users (email);
CREATE INDEX ON orders (user_id);
-- query
SELECT o.id FROM orders o JOIN users u ON u.id = o.user_id WHERE o.id = 123456 OR u.email = 'nhung.le500@outlook.com';
