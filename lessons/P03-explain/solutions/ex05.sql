-- db: lab
-- reset
-- expect-rows: 1
-- Giải thích: sort 400 000 dòng (amount, id): ở work_mem 4MB tràn → external merge, 7 072 kB trên đĩa (888 page ghi). Với work_mem đủ lớn quicksort tốn 21 664 kB RAM
--   (≈ 3.1× vì mỗi tuple trong RAM có thêm header/con trỏ). Thực nghiệm: 18MB vẫn tràn (Disk: 7048kB), 19MB đủ (Memory: 19103kB; bộ nhớ dùng phụ thuộc work_mem).
--   Vì vậy "work_mem cần để không tràn" ≠ "kích thước tràn trên đĩa".
-- Bẫy: lấy 7 072 kB / 1024 ≈ 7MB làm work_mem cần thiết (7MB vẫn tràn); quên tắt parallel khi thử.
SELECT 7072 AS disk_kb, 21664 AS mem_kb, round(21664 / 7072.0, 1) AS mem_to_disk, 888 AS temp_written_a, 19 AS min_work_mem_mb;
