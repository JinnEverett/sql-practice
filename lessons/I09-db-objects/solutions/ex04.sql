-- db: lab
-- mode: check
-- reset
-- Giải thích: materialized view LƯU kết quả truy vấn như một bảng; đọc rất nhanh nhưng cũ cho tới khi REFRESH. REFRESH thường khóa
--   ACCESS EXCLUSIVE (chặn cả SELECT). REFRESH … CONCURRENTLY chỉ khóa nhẹ, người đọc vẫn đọc bản cũ, nhưng ĐÒI HỎI ít nhất một UNIQUE index
--   (không điều kiện, không biểu thức) trên matview để so khớp dòng cũ/mới. Vì vậy: tạo matview xong phải tạo ngay unique index.
-- Bẫy: matview không có unique index → REFRESH CONCURRENTLY lỗi 55000; nhớ rằng matview không tự cập nhật (không trigger).
CREATE MATERIALIZED VIEW i09.mv_daily_revenue AS
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day,
       count(*) AS n_orders,
       sum(total) AS revenue
FROM i09.orders
WHERE status <> 'cancelled'
GROUP BY 1;
CREATE UNIQUE INDEX mv_daily_revenue_day ON i09.mv_daily_revenue (day);
