-- db: shop_s
-- ordered
-- Giải thích: với mỗi đơn, sinh 10 ngày kể từ ngày đặt (giờ VN) bằng generate_series trong LATERAL (hoặc subquery tương quan),
--   giữ ngày là thứ 2–6 (isodow < 6) và không nằm trong bảng ngày lễ, rồi lấy ngày nhỏ nhất.
--   Scalar subquery tương quan đọc dễ; LATERAL (I08) là cách viết tương đương.
-- Bẫy: chỉ xử lý cuối tuần (CASE isodow) mà quên ngày lễ; ngày lễ rơi ngay sau cuối tuần (T7 → CN → T2 lễ → T3).
WITH holidays (d) AS (
  VALUES (date '2026-09-01'), (date '2026-09-02')
), o AS (
  SELECT id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay_dat
  FROM orders
  WHERE created_at >= '2026-08-28 00:00+07' AND created_at < '2026-09-04 00:00+07'
    AND id % 5 = 0
)
SELECT o.id, o.ngay_dat, extract(isodow FROM o.ngay_dat)::int AS thu,
       (SELECT min(g::date)
        FROM generate_series(o.ngay_dat, o.ngay_dat + 10, interval '1 day') AS g
        WHERE extract(isodow FROM g) < 6
          AND g::date NOT IN (SELECT d FROM holidays)) AS ngay_xu_ly
FROM o
ORDER BY o.id;
