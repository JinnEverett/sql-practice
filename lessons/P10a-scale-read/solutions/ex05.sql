-- db: lab
-- mode: manual
-- Demo: sort có/không tràn work_mem trên t_m (tắt parallel để plan gọn). Xem `temp written` trong Buffers.
SET max_parallel_workers_per_gather = 0;
SET work_mem = '4MB';
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT count(*) FROM (SELECT id FROM p10.t_m ORDER BY amount, id) s;
SET work_mem = '64MB';
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT count(*) FROM (SELECT id FROM p10.t_m ORDER BY amount, id) s;
