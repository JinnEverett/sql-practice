-- db: lab
-- mode: manual
-- Demo: hai truy vấn cùng "một dòng kết quả" nhưng khác độ phức tạp (t_m).
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT max(u) FROM p10.t_m;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT max(amount) FROM p10.t_m;
