-- db: shop_s
-- ordered
WITH u AS (SELECT id FROM users WHERE deleted_at IS NULL),
mua   AS (SELECT id FROM u INTERSECT SELECT user_id FROM orders),
xem   AS ((SELECT id FROM u INTERSECT SELECT user_id FROM events) EXCEPT SELECT user_id FROM orders),
ngu   AS (SELECT id FROM u EXCEPT (SELECT user_id FROM orders UNION SELECT user_id FROM events))
SELECT nhom, count(*) AS n_khach FROM (
  SELECT 'mua hàng' AS nhom, id FROM mua
  UNION ALL SELECT 'chỉ xem', id FROM xem
  UNION ALL SELECT 'ngủ đông', id FROM ngu) t
GROUP BY nhom ORDER BY nhom;
