-- db: lab
-- reset
-- ordered
-- expect-rows: 5
-- Giải thích: sessionization = cắt dãy sự kiện của một visitor thành phiên bất cứ khi nào khoảng lặng > 30 phút. Hai cửa sổ liên tiếp:
--   (1) lag(at) cho thời điểm sự kiện trước; cờ is_new = 1 nếu là sự kiện đầu hoặc at − lag > 30 phút (đúng 30 phút vẫn cùng phiên);
--   (2) tổng lũy kế của cờ theo thời gian = số thứ tự phiên. GROUP BY (visitor, session_no) cho thống kê mỗi phiên.
-- Bẫy: dùng >= 30 phút (cắt nhầm khoảng đúng 30 phút của visitor a); quên PARTITION BY visitor (phiên chạy xuyên visitor); không có sự kiện đầu (lag NULL) nên cờ phải xử lý NULL.
WITH f AS (
  SELECT visitor, at,
         CASE WHEN at - lag(at) OVER (PARTITION BY visitor ORDER BY at) > interval '30 minutes'
                OR lag(at) OVER (PARTITION BY visitor ORDER BY at) IS NULL THEN 1 ELSE 0 END AS is_new
  FROM r07.hits
), s AS (
  SELECT visitor, at, sum(is_new) OVER (PARTITION BY visitor ORDER BY at) AS session_no FROM f
)
SELECT visitor, session_no::int AS session_no, min(at) AS started_at, max(at) AS ended_at,
       count(*) AS n_events, max(at) - min(at) AS duration
FROM s
GROUP BY visitor, session_no
ORDER BY visitor, session_no;
