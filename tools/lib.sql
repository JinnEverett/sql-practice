-- tools/lib.sql · hàm hỗ trợ cho bộ test (mode: check). Tạo trong pg_temp nên chỉ sống trong phiên chấm.
-- Gọi bằng tên đầy đủ: pg_temp.ck(...), pg_temp.plan(...), ...
SET client_min_messages = notice;

-- In PASS/FAIL. Notice không bị mất khi transaction ROLLBACK.
CREATE FUNCTION pg_temp.ck(ok boolean, msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF ok IS TRUE THEN RAISE NOTICE 'PASS: %', msg; ELSE RAISE NOTICE 'FAIL: %', msg; END IF;
END $$;

-- Bỏ dấu ; và comment ở cuối câu lệnh để nhúng được vào EXECUTE / subquery.
CREATE FUNCTION pg_temp.clean(q text) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT regexp_replace(q, '(\s|;|--[^\n]*)*$', '')
$$;

-- Plan của câu lệnh q dưới dạng jsonb (phần tử đầu của EXPLAIN FORMAT JSON).
CREATE FUNCTION pg_temp.plan(q text, do_analyze boolean DEFAULT true) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE r json;
BEGIN
  IF do_analyze THEN
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || pg_temp.clean(q) INTO r;
  ELSE
    EXECUTE 'EXPLAIN (FORMAT JSON) ' || pg_temp.clean(q) INTO r;
  END IF;
  RETURN (r::jsonb) -> 0;
END $$;

-- Plan có node loại `node` (vd 'Seq Scan'), tùy chọn trên bảng `rel`?
CREATE FUNCTION pg_temp.has_node(p jsonb, node text, rel text DEFAULT NULL) RETURNS boolean LANGUAGE sql AS $$
  SELECT CASE WHEN rel IS NULL
    THEN jsonb_path_exists(p, '$.** ? (@."Node Type" == $n)', jsonb_build_object('n', node))
    ELSE jsonb_path_exists(p, '$.** ? (@."Node Type" == $n && @."Relation Name" == $r)', jsonb_build_object('n', node, 'r', rel))
  END
$$;

-- Plan có dùng index tên `idx` không (Index Scan / Index Only Scan / Bitmap Index Scan)?
CREATE FUNCTION pg_temp.uses_index(p jsonb, idx text DEFAULT NULL) RETURNS boolean LANGUAGE sql AS $$
  SELECT CASE WHEN idx IS NULL
    THEN jsonb_path_exists(p, '$.** ? (@."Index Name" != null)')
    ELSE jsonb_path_exists(p, '$.** ? (@."Index Name" == $i)', jsonb_build_object('i', idx))
  END
$$;

-- Tổng shared buffers (hit + read) ở node gốc, thời gian thực thi (ms), số dòng trả về, temp blocks đã ghi.
CREATE FUNCTION pg_temp.buffers(p jsonb) RETURNS bigint LANGUAGE sql AS $$
  SELECT coalesce((p #>> '{Plan,Shared Hit Blocks}')::bigint, 0) + coalesce((p #>> '{Plan,Shared Read Blocks}')::bigint, 0)
$$;
CREATE FUNCTION pg_temp.exec_ms(p jsonb) RETURNS numeric LANGUAGE sql AS $$ SELECT (p ->> 'Execution Time')::numeric $$;
CREATE FUNCTION pg_temp.rows_out(p jsonb) RETURNS bigint LANGUAGE sql AS $$ SELECT (p #>> '{Plan,Actual Rows}')::numeric::bigint $$;
CREATE FUNCTION pg_temp.temp_written(p jsonb) RETURNS bigint LANGUAGE sql AS $$
  SELECT coalesce(sum(v::bigint), 0) FROM jsonb_path_query(p, '$.**."Temp Written Blocks"') v
$$;

-- Hai câu SELECT trả về cùng một multiset dòng?
CREATE FUNCTION pg_temp.same(q1 text, q2 text) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
  EXECUTE format('SELECT count(*) FROM (((%1$s) EXCEPT ALL (%2$s)) UNION ALL ((%2$s) EXCEPT ALL (%1$s))) d',
                 pg_temp.clean(q1), pg_temp.clean(q2)) INTO n;
  RETURN n = 0;
END $$;

-- Chạy q, kỳ vọng LỖI có SQLSTATE bắt đầu bằng `state` (vd '23505' unique, '23503' FK, '23514' CHECK, '23502' NOT NULL, '23P01' exclusion).
-- Khối EXCEPTION tạo savepoint ngầm nên lỗi không phá transaction ngoài.
CREATE FUNCTION pg_temp.fails(q text, state text DEFAULT '') RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE q;
  RETURN false;
EXCEPTION WHEN others THEN
  RETURN SQLSTATE LIKE state || '%';
END $$;

-- Chạy q, kỳ vọng THÀNH CÔNG (không lỗi).
CREATE FUNCTION pg_temp.ok(q text) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE q;
  RETURN true;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'INFO: lỗi khi chạy [%]: %', left(q, 80), SQLERRM;
  RETURN false;
END $$;

-- Giá trị scalar của 1 câu SELECT (dạng text) để so sánh nhanh.
CREATE FUNCTION pg_temp.val(q text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE r text;
BEGIN
  EXECUTE pg_temp.clean(q) INTO r;
  RETURN r;
END $$;

-- ===== [nhóm r] Mô phỏng nhiều session bằng dblink (R04, R08, R10) =====
-- Cần: CREATE EXTENSION IF NOT EXISTS dblink; (superuser, DB lab). Dữ liệu cần được COMMIT thì session khác mới thấy
-- (bài dùng các hàm này thường `-- reset` và KHÔNG bọc trong BEGIN…ROLLBACK).
-- Mở kết nối `conn` tới DB hiện tại rồi gửi q chạy nền (không chờ). q có thể gồm nhiều lệnh: 'BEGIN; …; SELECT pg_sleep(2); COMMIT'.
CREATE FUNCTION pg_temp.bg_start(conn text, q text, db text DEFAULT current_database()) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM dblink_connect(conn, format('dbname=%s user=postgres', db));
  PERFORM dblink_send_query(conn, q);
END $$;

-- Chờ session nền xong. Trả về giá trị cột đầu của mọi kết quả nối bằng ' | ', hoặc 'ERROR <sqlstate>: <message>' nếu có lỗi.
-- Lưu ý: kết quả SELECT 0 dòng làm vòng chờ dừng sớm, nên đặt SELECT cần đọc ở cuối chuỗi lệnh.
CREATE FUNCTION pg_temp.bg_wait(conn text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE r text; n int; res text := ''; i int;
BEGIN
  FOR i IN 1..50 LOOP
    SELECT count(*), string_agg(x, ',') INTO n, r FROM dblink_get_result(conn, true) AS t(x text);
    EXIT WHEN n = 0;
    res := res || CASE WHEN res = '' THEN '' ELSE ' | ' END || coalesce(r, '');
  END LOOP;
  PERFORM dblink_disconnect(conn);
  RETURN res;
EXCEPTION WHEN others THEN
  BEGIN PERFORM dblink_disconnect(conn); EXCEPTION WHEN others THEN NULL; END;
  RETURN 'ERROR ' || SQLSTATE || ': ' || SQLERRM;
END $$;

-- Chạy đồng bộ q trên một session khác (mở rồi đóng ngay), trả về giá trị cột đầu của dòng cuối (text) hoặc 'ERROR …'.
CREATE FUNCTION pg_temp.bg_run(q text, db text DEFAULT current_database()) RETURNS text LANGUAGE plpgsql AS $$
DECLARE r text;
BEGIN
  PERFORM dblink_connect('bg_run_tmp', format('dbname=%s user=postgres', db));
  SELECT x INTO r FROM dblink('bg_run_tmp', q, true) AS t(x text) LIMIT 1;
  PERFORM dblink_disconnect('bg_run_tmp');
  RETURN r;
EXCEPTION WHEN others THEN
  BEGIN PERFORM dblink_disconnect('bg_run_tmp'); EXCEPTION WHEN others THEN NULL; END;
  RETURN 'ERROR ' || SQLSTATE || ': ' || SQLERRM;
END $$;
