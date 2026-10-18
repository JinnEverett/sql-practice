-- db: lab
-- mode: check
-- reset
-- Giải thích: partition pruning (cắt tỉa): planner chỉ quét các partition mà khoảng của chúng giao với điều kiện lọc trên KHÓA partition. Điều kiện phải so sánh trực tiếp cột `ts`
--   với hằng/tham số cùng kiểu. Bọc cột trong hàm (date_trunc(…), ts::date, extract(…), AT TIME ZONE) làm planner không suy ra được khoảng nào của ts thỏa → quét MỌI partition.
--   "Tháng 3 giờ Việt Nam" là [2026-03-01 00:00+07, 2026-04-01 00:00+07) = [2026-02-28 17:00 UTC, 2026-03-31 17:00 UTC) giao với 2 partition UTC: tháng 2 (7 giờ cuối) và tháng 3.
--   Kết quả đúng nhưng pruning đúng mới là mục tiêu: bộ chấm kiểm tra cả plan (không cần chạy: constants được cắt ngay lúc lập kế hoạch).
-- Bẫy: date_trunc('month', ts AT TIME ZONE 'Asia/Ho_Chi_Minh') = '2026-03-01' đúng nghĩa nhưng quét cả 6 partition; chỉ lọc theo [03-01, 04-01) UTC cho kết quả sai (lệch 7 giờ).
SELECT count(*) AS n_events, round(avg(value), 2) AS avg_value
FROM r12.events_p
WHERE ts >= '2026-03-01 00:00+07' AND ts < '2026-04-01 00:00+07';
