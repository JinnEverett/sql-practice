-- db: lab
-- mode: state
-- Giải thích: rollup = tổng hợp dữ liệu thô theo giờ thành bảng theo ngày để dashboard đọc rẻ. Phải IDEMPOTENT: chạy lại (retry, chạy bù) không được nhân đôi số liệu.
--   INSERT … ON CONFLICT (sensor, day) DO UPDATE ghi đè bằng số vừa tính lại cho các ngày trong khoảng, nên dòng cũ sai (sensor 1, ngày 2026-03-02) được sửa; ngày chưa có thì chèn mới.
--   "Ngày" theo giờ Việt Nam, khoảng lọc theo ts nửa mở bằng hằng cùng kiểu để dùng được index/pruning. Chỉ recompute những ngày ĐÃ ĐÓNG (không tính ngày chưa kết thúc).
-- Bẫy: DO NOTHING giữ nguyên dòng cũ sai; INSERT trơn → lỗi 23505 ở lần chạy lại; GROUP BY ts::date theo UTC lệch ngày; cộng dồn vào số cũ (sum_value = sum_value + …) làm đếm đôi khi chạy lại.
INSERT INTO r12.metrics_daily (sensor, day, n, sum_value, min_value, max_value)
SELECT sensor, (ts AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, count(*), sum(value), min(value), max(value)
FROM r12.metrics_raw
WHERE ts >= '2026-03-01 00:00+07' AND ts < '2026-03-04 00:00+07'
GROUP BY sensor, (ts AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
ON CONFLICT (sensor, day) DO UPDATE
  SET n = EXCLUDED.n, sum_value = EXCLUDED.sum_value, min_value = EXCLUDED.min_value, max_value = EXCLUDED.max_value;
