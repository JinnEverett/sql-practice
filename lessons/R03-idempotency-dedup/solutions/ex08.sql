-- db: shop_s
-- mode: manual
-- Demo: ba cách tìm email trùng (đã chuẩn hóa) trên users. Đổi sang shop_m để thấy HashAggregate/Sort tràn ra đĩa với work_mem = 4MB.
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT lower(btrim(email)), count(*) FROM users GROUP BY 1 HAVING count(*) > 1;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id FROM (SELECT id, row_number() OVER (PARTITION BY lower(btrim(email)) ORDER BY created_at, id) rn FROM users) t WHERE rn > 1;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT a.id FROM users a JOIN users b ON lower(btrim(a.email)) = lower(btrim(b.email)) AND a.id > b.id;
