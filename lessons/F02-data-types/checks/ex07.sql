-- db: lab
-- ordered
SELECT id, is_paid, total_vnd FROM f02.legacy_orders
WHERE is_paid::boolean ORDER BY id;
