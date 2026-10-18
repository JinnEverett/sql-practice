-- db: shop_s
-- ordered
-- expect-rows: 3
-- Giải thích: status chỉ có 6 giá trị nên cả 6 đều vào MCV (và phần còn lại rỗng nên không cần histogram). total_amount có ~5 564 giá trị khác nhau trên 10 000 dòng;
--   n_distinct âm (-0.5564) nghĩa là "tỉ lệ so với số dòng" để khi bảng lớn lên con số vẫn có nghĩa. 100 MCV + histogram 101 mốc (100 thùng) cho phần còn lại.
-- Bẫy: array_length trả NULL (không phải 0) cho mảng NULL → cần coalesce; nhầm n_distinct âm là lỗi.
SELECT attname,
       round(n_distinct::numeric, 3) AS n_distinct,
       round(null_frac::numeric, 3)  AS null_frac,
       coalesce(array_length(most_common_vals::text::text[], 1), 0)   AS n_mcv,
       coalesce(array_length(histogram_bounds::text::text[], 1), 0)   AS n_hist_bounds
FROM pg_stats
WHERE schemaname = 'public' AND tablename = 'orders' AND attname IN ('status', 'discount_code', 'total_amount')
ORDER BY attname;
