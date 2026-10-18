-- db: lab
-- mode: check
-- reset
-- Giải thích: partition theo thời gian cần được TẠO TRƯỚC khi dữ liệu tới (nếu không INSERT bị từ chối, hoặc rơi vào DEFAULT rồi sau này không tạo được partition cho khoảng đó nếu DEFAULT đã chứa dòng thuộc khoảng).
--   Hàm ensure_month(ngày) tính ranh giới tháng UTC, tạo partition `events_p_YYYY_MM` bằng CREATE TABLE IF NOT EXISTS … PARTITION OF (idempotent), trả về tên partition. Chạy bằng job định kỳ
--   (pg_cron hoặc cron của hệ điều hành) tạo trước 1–3 tháng. Tên lấy từ date_trunc nên không phụ thuộc đầu vào người dùng; vẫn dùng %I/%L để trích dẫn đúng.
--   IF NOT EXISTS chỉ kiểm tra TÊN, không kiểm tra ranh giới: tên đã có nhưng khoảng khác → hàm im lặng không làm gì. Thêm kiểm tra nếu cần chặt hơn.
-- Bẫy: nối chuỗi không trích dẫn; tháng 12 → tháng 1 năm sau (dùng interval '1 month' chứ không phải cộng 1 vào số tháng); ranh giới theo múi giờ phiên thay vì UTC tường minh.
CREATE FUNCTION r12.ensure_month(p_day date) RETURNS text LANGUAGE plpgsql AS $$
DECLARE
  d0   date := date_trunc('month', p_day)::date;
  d1   date := (date_trunc('month', p_day) + interval '1 month')::date;
  pname text := 'events_p_' || to_char(d0, 'YYYY_MM');
BEGIN
  EXECUTE format('CREATE TABLE IF NOT EXISTS r12.%I PARTITION OF r12.events_p FOR VALUES FROM (%L) TO (%L)',
                 pname, d0::text || ' 00:00+00', d1::text || ' 00:00+00');
  RETURN pname;
END $$;
