-- db: lab
-- mode: check
-- reset
-- Giải thích: 1M tuple (amount, id) trong bộ nhớ chiếm ~46 MB (45 MB vẫn ghi 6 612 page tạm; 46 MB thì không): mỗi tuple sort tốn nhiều hơn 8 byte dữ liệu vì header, con trỏ và đệm.
--   Khi tràn, 6 612 page (≈ 52 MB) được ghi ra file tạm.
-- Bẫy: ước lượng bằng 1M × 8 byte = 8 MB; quên tắt parallel (mỗi worker dùng work_mem riêng và sort nhỏ hơn).
SELECT 46 AS min_work_mem_mb;
