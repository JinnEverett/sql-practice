CREATE INDEX ON orders (user_id);
-- query
SELECT count(*) FROM users u LEFT JOIN orders o ON o.user_id = u.id WHERE o.id IS NULL;
