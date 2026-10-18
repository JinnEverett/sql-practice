SELECT attname, round(n_distinct::numeric, 3) AS n_distinct, round(null_frac::numeric, 3) AS null_frac,
       array_length(most_common_vals::text::text[], 1) AS n_mcv, array_length(histogram_bounds::text::text[], 1) AS n_hist_bounds
FROM pg_stats WHERE schemaname = 'public' AND tablename = 'orders' AND attname IN ('status', 'discount_code', 'total_amount') ORDER BY attname;
