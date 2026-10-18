-- db: lab
-- reset
-- expect-rows: 1
-- Giải thích: Nested Loop: phía ngoài 5 dòng (u.id <= 5) → phía trong chạy loops=5, mỗi loop 20 dòng (khách có 20 đơn) → 100 dòng ra.
--   "Heap Blocks: exact=100" cộng dồn cả 5 loop (20 page mỗi lần, mỗi dòng một page). actual time cũng là MỖI loop: 0.021 ms × 5 ≈ 0.1 ms thật.
-- Bẫy: đọc rows=20.00 là tổng của phía trong (thật ra là mỗi loop).
SELECT (SELECT count(*) FROM p03.u WHERE id <= 5) AS outer_rows,
       5 AS loops,
       20 AS rows_per_loop,
       (SELECT count(*) FROM p03.u u JOIN p03.o o ON o.user_id = u.id WHERE u.id <= 5) AS rows_returned,
       100 AS heap_blocks;
