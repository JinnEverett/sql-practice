-- db: lab
-- mode: check
-- reset
-- Giải thích: thống kê cột `kind` chỉ biết a/b/c (mỗi giá trị 1/3). 'new' không có trong MCV → ước lượng ≈ 0 → làm tròn lên 1 dòng, trong khi thực tế 100 000
--   (2/3 bảng). ANALYZE thu thập lại: 'new' chiếm 66.7%. Bài học vận hành: ANALYZE ngay sau mỗi lần nạp hàng loạt, không chờ autovacuum.
-- Bẫy: VACUUM thường (cập nhật reltuples nhưng không thống kê cột); ANALYZE nhầm bảng; chặn nestloop/seqscan bằng SET (che triệu chứng); thêm index.
ANALYZE p04.job;
