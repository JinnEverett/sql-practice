WITH o AS (SELECT id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay_dat FROM orders
           WHERE created_at >= '2026-08-28 00:00+07' AND created_at < '2026-09-04 00:00+07' AND id % 5 = 0)
SELECT o.id, o.ngay_dat, extract(isodow FROM o.ngay_dat)::int AS thu,
       CASE extract(isodow FROM o.ngay_dat) WHEN 6 THEN o.ngay_dat + 2 WHEN 7 THEN o.ngay_dat + 1 ELSE o.ngay_dat END AS ngay_xu_ly
FROM o ORDER BY o.id;
