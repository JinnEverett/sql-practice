-- Lời giải SAI: cộng dồn theo thứ tự tên dịch vụ thay vì từ dịch vụ lớn nhất.
WITH t AS (
  SELECT app, instances * pool_size AS total_conns FROM o04.apps
)
SELECT app, total_conns,
       sum(total_conns) OVER (ORDER BY app) AS running_total,
       sum(total_conns) OVER (ORDER BY app) <= 100 - 3 - 0 AS fits
FROM t ORDER BY total_conns DESC;
