WITH b AS (SELECT id, product_id, moved_at, qty, sum(qty) OVER (PARTITION BY product_id ORDER BY moved_at) AS balance FROM i04.stock_moves),
neg AS (SELECT *, row_number() OVER (PARTITION BY product_id ORDER BY moved_at, id) AS k FROM b WHERE balance < 0)
SELECT product_id, id AS move_id, moved_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS moved_at_vn, qty, balance FROM neg WHERE k = 1 ORDER BY product_id;
