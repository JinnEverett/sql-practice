-- db: lab
-- mode: manual
-- Demo: một ô của bảng sweep (1% bảng, cột u) ở t_m. Với t_l cần chạy setup-large.sql trước.
EXPLAIN (ANALYZE, BUFFERS) SELECT count(amount) FROM p10.t_m WHERE u < 10000;
