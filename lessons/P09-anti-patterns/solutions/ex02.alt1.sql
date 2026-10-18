CREATE INDEX ON orders ((user_id::text));
-- query
SELECT id, total_amount FROM orders WHERE user_id::text = '4242';
