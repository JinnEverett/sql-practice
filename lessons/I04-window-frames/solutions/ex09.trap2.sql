WITH b AS (SELECT id, product_id, moved_at, qty, sum(qty) OVER (PARTITION BY product_id ORDER BY moved_at, id) AS balance FROM i04.stock_moves)
SELECT product_id, id AS move_id, moved_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS moved_at_vn, qty, balance FROM b WHERE balance < 0 ORDER BY product_id;
