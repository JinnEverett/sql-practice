-- Hàm đo hiệu năng dùng chung (bench.sh gọi). Idempotent: chạy lại bao nhiêu lần cũng được.
SET client_min_messages = warning;
CREATE SCHEMA IF NOT EXISTS bench;

-- EXPLAIN (ANALYZE, BUFFERS) một câu lệnh rồi HỦY mọi thay đổi dữ liệu nó gây ra.
-- Nhờ vậy đo được cả INSERT/UPDATE/DELETE nhiều lần mà dữ liệu không đổi.
CREATE OR REPLACE FUNCTION bench.explain(q text) RETURNS jsonb
LANGUAGE plpgsql AS $fn$
DECLARE
  plan jsonb;
BEGIN
  BEGIN
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) '
            || regexp_replace(q, ';(\s|--[^\n]*)*$', '')
      INTO plan;
    -- Ném lỗi để rollback subtransaction; biến plan vẫn giữ giá trị.
    RAISE EXCEPTION USING ERRCODE = 'BN001', MESSAGE = 'bench rollback';
  EXCEPTION WHEN SQLSTATE 'BN001' THEN
    NULL;
  END;
  RETURN plan -> 0;
END
$fn$;

-- Chạy q `runs` lần, trả về median thời gian + tóm tắt plan của lần chạy cuối.
CREATE OR REPLACE FUNCTION bench.run(q text, runs int DEFAULT 3)
RETURNS TABLE (
  exec_ms     numeric,   -- median Execution Time
  exec_min    numeric,
  exec_max    numeric,
  plan_ms     numeric,   -- Planning Time
  out_rows    bigint,    -- số dòng node gốc trả ra
  nodes       text,      -- các node trong plan theo thứ tự duyệt, bỏ trùng
  shared_hit  bigint,    -- block 8KB đọc từ shared_buffers
  shared_read bigint,    -- block 8KB phải đọc từ OS/đĩa
  temp_mb     numeric    -- dữ liệu tạm tràn ra đĩa (sort/hash vượt work_mem)
)
LANGUAGE plpgsql AS $fn$
DECLARE
  e     jsonb;
  times numeric[] := '{}';
BEGIN
  FOR i IN 1..runs LOOP
    e := bench.explain(q);
    times := times || (e ->> 'Execution Time')::numeric;
  END LOOP;

  RETURN QUERY
  SELECT
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY t) FROM unnest(times) t)::numeric(14,2),
    (SELECT min(t) FROM unnest(times) t)::numeric(14,2),
    (SELECT max(t) FROM unnest(times) t)::numeric(14,2),
    (e ->> 'Planning Time')::numeric(14,2),
    (e -> 'Plan' ->> 'Actual Rows')::numeric::bigint,
    (SELECT string_agg(lbl, ' › ' ORDER BY first_ord)
     FROM (SELECT lbl, min(ord) AS first_ord
           FROM (SELECT nd ->> 'Node Type'
                          || coalesce(' [' || coalesce(nd ->> 'Index Name', nd ->> 'Relation Name') || ']', '')
                          AS lbl,
                        ord
                 FROM jsonb_path_query(e -> 'Plan', 'strict $.** ? (exists (@."Node Type"))')
                      WITH ORDINALITY AS x(nd, ord)) a
           GROUP BY lbl) b),
    (e -> 'Plan' ->> 'Shared Hit Blocks')::bigint,
    (e -> 'Plan' ->> 'Shared Read Blocks')::bigint,
    round((coalesce((e -> 'Plan' ->> 'Temp Read Blocks')::numeric, 0)
           + coalesce((e -> 'Plan' ->> 'Temp Written Blocks')::numeric, 0)) * 8 / 1024, 1);
END
$fn$;
