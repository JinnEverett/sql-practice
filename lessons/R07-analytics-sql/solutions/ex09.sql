-- db: shop_s
-- mode: manual
-- Demo: sessionization toàn bộ bảng events (ex05 áp dụng cho dữ liệu thật). Chạy ở shop_s (32k event, ~70 ms);
-- đổi sang shop_m để tái hiện số đo ở ex09.md (3.2M event, ~11 giây).
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
WITH f AS (
  SELECT coalesce(user_id::text, anonymous_id) AS visitor, created_at,
         CASE WHEN created_at - lag(created_at) OVER w > interval '30 minutes' OR lag(created_at) OVER w IS NULL THEN 1 ELSE 0 END AS is_new
  FROM events
  WINDOW w AS (PARTITION BY coalesce(user_id::text, anonymous_id) ORDER BY created_at)
), s AS (
  SELECT visitor, sum(is_new) OVER (PARTITION BY visitor ORDER BY created_at) AS session_no FROM f
)
SELECT count(*) FROM (SELECT visitor, session_no FROM s GROUP BY 1, 2) x;

-- Biến thể: khóa phân vùng dùng collation "C" (so sánh byte, không theo ngôn ngữ). Phân vùng chỉ cần GOM nhóm, không cần thứ tự ngôn ngữ.
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
WITH f AS (
  SELECT coalesce(user_id::text, anonymous_id) COLLATE "C" AS visitor, created_at,
         CASE WHEN created_at - lag(created_at) OVER w > interval '30 minutes' OR lag(created_at) OVER w IS NULL THEN 1 ELSE 0 END AS is_new
  FROM events
  WINDOW w AS (PARTITION BY coalesce(user_id::text, anonymous_id) COLLATE "C" ORDER BY created_at)
), s AS (
  SELECT visitor, sum(is_new) OVER (PARTITION BY visitor ORDER BY created_at) AS session_no FROM f
)
SELECT count(*) FROM (SELECT visitor, session_no FROM s GROUP BY 1, 2) x;
