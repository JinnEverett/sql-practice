-- db: lab
-- reset
-- expect-rows: 1
-- Giải thích: Parallel Seq Scan có loops=3 (leader + 2 worker). actual rows và Rows Removed đều tính MỖI loop: 118 666.67 × 3 = 356 000 đơn delivered
--   và 14 667 × 3 = 44 000 đơn bị loại (pending + cancelled); 356 000 + 44 000 = 400 000. Buffers ở node con là tổng của mọi worker = 3 334 = số page bảng o.
-- Bẫy: lấy actual rows của node (118 667) làm tổng; tưởng workers_launched = loops (loops là 3 vì tính cả leader).
SELECT 2 AS workers_launched,
       count(*) FILTER (WHERE status = 'delivered')  AS matched_rows,
       count(*) FILTER (WHERE status <> 'delivered') AS removed_rows,
       pg_relation_size('p03.o') / 8192              AS buffers
FROM p03.o;
