-- db: lab
-- mode: check
-- reset
-- Giải thích: pg_stat_statements gộp các câu lệnh cùng "hình dạng" (hằng số thành $1, $2) và cộng dồn calls, total_exec_time, rows, số block…
--   "Tệ nhất" phải định nghĩa theo mục đích: sắp theo TỔNG thời gian (total_exec_time) cho biết query nào chiếm nhiều tài nguyên nhất;
--   sắp theo mean_exec_time cho biết query chậm nhất mỗi lần gọi nhưng có thể hiếm khi chạy. Thường bắt đầu từ total_exec_time.
--   Loại các câu truy vấn chính pg_stat_statements để khỏi tự đo chính mình.
-- Bẫy: sắp theo mean_exec_time (lôi query gọi 1 lần lên đầu); quên loại câu lệnh của chính pg_stat_statements; làm tròn bằng ép ::int làm mất phần lẻ.
SELECT left(query, 80) AS query,
       calls,
       round(total_exec_time::numeric, 1) AS total_ms,
       round(mean_exec_time::numeric, 2) AS mean_ms
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 5;
