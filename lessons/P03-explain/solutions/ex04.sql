-- db: lab
-- reset
-- expect-rows: 1
-- Giải thích: bảng nhỏ u (20 000 dòng, 1 131 kB) được băm; ở work_mem 4MB vừa RAM nên Batches 1. Với work_mem 64kB hash table chỉ chứa 1/8 mỗi lần
--   → 8 batch: u ghi ra 49 page tạm, và phía quét o (400 000 dòng) cũng bị chia theo cùng hàm băm vào file tạm → tổng 1 081 page ghi (và đọc lại),
--   gấp 8× kích thước u. Chi phí tràn hash tỉ lệ với bảng LỚN, không phải bảng nhỏ.
-- Bẫy: tưởng temp ≈ kích thước build side; tưởng bảng lớn mới là bảng được băm.
SELECT 'u' AS build_table,
       (SELECT count(*) FROM p03.u) AS build_rows,
       1 AS batches_a,
       8 AS batches_b,
       1081 AS temp_written_b;
