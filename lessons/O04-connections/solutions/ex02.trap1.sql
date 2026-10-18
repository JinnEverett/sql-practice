-- Lời giải SAI: quên nhân với số bản chạy (instances), chỉ cộng pool_size của một bản.
WITH t AS (
  SELECT app, pool_size AS total_conns FROM o04.apps
)
SELECT app, total_conns,
       sum(total_conns) OVER (ORDER BY total_conns DESC) AS running_total,
       sum(total_conns) OVER (ORDER BY total_conns DESC) <= 100 - 3 - 0 AS fits
FROM t ORDER BY total_conns DESC;
