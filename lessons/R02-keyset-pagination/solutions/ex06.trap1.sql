-- sai: chỉ so created_at → mất các bài cùng created_at với dòng cursor
CREATE FUNCTION r02.feed_page(p_ts timestamptz, p_id bigint, p_size int)
RETURNS TABLE (id bigint, created_at timestamptz, title text) LANGUAGE sql STABLE AS $$
  SELECT f.id, f.created_at, f.title FROM r02.feed f
  WHERE p_ts IS NULL OR f.created_at < p_ts
  ORDER BY f.created_at DESC, f.id DESC LIMIT p_size
$$;
