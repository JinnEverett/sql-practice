-- db: lab
-- mode: query
-- ordered
-- reset
-- expect-rows: 5
-- Giải thích: tổng kết nối của một dịch vụ = số bản chạy × cỡ pool MỖI bản (không phải chỉ pool_size). Cộng dồn từ dịch vụ lớn nhất,
--   so với 100 − 3 − 0 = 97 kết nối dùng được. Ở đây api (60) + reports (24) = 84 còn vừa; thêm worker (20) là 104 > 97: vỡ.
--   Đây là con số cần có TRƯỚC khi thêm bản chạy mới hay tăng pool, và là lý do cần PgBouncer.
-- Bẫy: dùng pool_size mà quên nhân instances; sắp cộng dồn theo tên thay vì theo cỡ; dùng 100 thay vì 97.
WITH t AS (
  SELECT app, instances * pool_size AS total_conns FROM o04.apps
)
SELECT app,
       total_conns,
       sum(total_conns) OVER (ORDER BY total_conns DESC) AS running_total,
       sum(total_conns) OVER (ORDER BY total_conns DESC) <= 100 - 3 - 0 AS fits
FROM t
ORDER BY total_conns DESC;
