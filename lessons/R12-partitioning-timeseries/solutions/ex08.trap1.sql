-- sai: tháng 12 → cộng 1 vào số tháng (ranh giới 2026-13-01 không hợp lệ) và không idempotent
CREATE FUNCTION r12.ensure_month(p_day date) RETURNS text LANGUAGE plpgsql AS $$
DECLARE pname text := 'events_p_' || to_char(p_day, 'YYYY_MM');
BEGIN
  EXECUTE format('CREATE TABLE r12.%I PARTITION OF r12.events_p FOR VALUES FROM (%L) TO (%L)', pname,
    to_char(p_day, 'YYYY-MM') || '-01 00:00+00',
    to_char(date_part('year', p_day), 'FM9999') || '-' || to_char(date_part('month', p_day) + 1, 'FM00') || '-01 00:00+00');
  RETURN pname;
END $$;
