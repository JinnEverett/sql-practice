-- db: shop_m
-- mode: check
-- Giải thích: `id NOT IN (SELECT user_id FROM orders)`: subquery 1M dòng không vừa work_mem nên planner không băm được → SubPlan + Materialize, lặp lại cho mỗi user: cost ước lượng 1.7 tỉ (hàng giờ).
--   Ngoài tốc độ còn có bẫy đúng/sai: nếu subquery có NULL thì NOT IN trả rỗng. NOT EXISTS (hoặc LEFT JOIN … IS NULL) biến thành anti-join băm: 12 207 buffers (không index), ~2 650 với index orders(user_id).
-- Bẫy: NOT IN (chậm và nhạy NULL); LEFT JOIN rồi `count(*)` quên điều kiện IS NULL.
-- query
SELECT count(*) FROM users u WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
