-- db: lab
-- mode: check
-- reset
-- Giải thích: thời gian chỉ là một góc nhìn. Số block đã chạm (shared_blks_hit + shared_blks_read) cho biết query "ăn" bao nhiêu I/O/bộ nhớ đệm,
--   ổn định hơn thời gian (không phụ thuộc máy bận hay không). blks_per_call = tổng block / calls phân biệt "gọi rất nhiều lần nhưng mỗi lần nhẹ"
--   với "mỗi lần quét cả bảng". Một block = 8 kB.
-- Bẫy: chỉ nhìn shared_blks_read (phụ thuộc cache có nóng hay không, lần chạy sau về 0); sắp theo calls; chia cho 0 khi calls = 0 (calls ≥ 1 với entry hiện có nhưng nên nullif).
SELECT left(query, 80) AS query,
       calls,
       shared_blks_hit + shared_blks_read AS blks_total,
       round((shared_blks_hit + shared_blks_read)::numeric / nullif(calls, 0), 1) AS blks_per_call
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat_statements%'
ORDER BY blks_total DESC
LIMIT 3;
