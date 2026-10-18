-- db: lab
-- mode: check
-- reset
-- Giải thích: hàm nhận cursor (ts, id) của dòng CUỐI trang trước; NULL = trang đầu. Điều kiện (created_at, id) < (p_ts, p_id) là ổn định:
--   dòng mới chèn (created_at lớn hơn) nằm TRƯỚC cursor nên không làm lệch trang đang đọc, khác với OFFSET (mọi dòng bị đẩy xuống → lặp).
-- Bẫy: created_at < p_ts (mất dòng trùng giờ); xử lý NULL bằng IF riêng (đúng) hay bằng coalesce(p_ts, 'infinity') (cũng đúng, gọn hơn).
CREATE FUNCTION r02.feed_page(p_ts timestamptz, p_id bigint, p_size int)
RETURNS TABLE (id bigint, created_at timestamptz, title text)
LANGUAGE sql STABLE AS $$
  SELECT f.id, f.created_at, f.title
  FROM r02.feed f
  WHERE p_ts IS NULL OR (f.created_at, f.id) < (p_ts, p_id)
  ORDER BY f.created_at DESC, f.id DESC
  LIMIT p_size
$$;
