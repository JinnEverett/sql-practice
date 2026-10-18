-- D09 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d09;
SET client_min_messages = warning;

-- §0 Seed kho phân tích: 1M dòng fact trong 365 ngày (giờ VN), 40 ngành hàng; rollup dựng từ fact
INSERT INTO sales_fact (sold_at, order_id, product_id, category_id, qty, amount)
SELECT timestamptz '2025-10-01' + g * interval '31 seconds', g, 1 + g % 5000, 1 + (g * 7) % 40, 1 + g % 3, (1 + g % 50) * 10000
FROM generate_series(1, 1000000) g;
INSERT INTO daily_rollup (day, category_id, orders, revenue)
SELECT (sold_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date, category_id, count(DISTINCT order_id), sum(amount)
FROM sales_fact GROUP BY 1, 2;
-- BRIN chỉ lọc được các range ĐÃ được tóm tắt: sau nạp hàng loạt phải VACUUM (hoặc brin_summarize_new_values / autosummarize)
VACUUM (ANALYZE) sales_fact;
ANALYZE;
SELECT count(*) AS fact_rows, (SELECT count(*) FROM daily_rollup) AS rollup_rows FROM sales_fact;

-- §1 Outbox cùng transaction với nghiệp vụ: đơn lỗi thì sự kiện cũng không tồn tại
DO $$
DECLARE o bigint; hit boolean := false; before_n bigint; after_n bigint;
BEGIN
    o := place_order(1, '[{"product_id":1,"category_id":3,"qty":2,"amount":50000},{"product_id":2,"category_id":4,"qty":1,"amount":20000}]');
    ASSERT (SELECT count(*) FROM outbox WHERE aggregate_id = o AND event_type = 'OrderPlaced') = 1, 'mỗi đơn đúng 1 sự kiện';
    SELECT count(*) INTO before_n FROM outbox;
    BEGIN PERFORM place_order(1, '[{"product_id":1,"category_id":3,"qty":1,"amount":-5}]');      -- total âm => CHECK fail
    EXCEPTION WHEN check_violation THEN hit := true; END;
    SELECT count(*) INTO after_n FROM outbox;
    ASSERT hit AND before_n = after_n, 'đơn lỗi không được để lại sự kiện';
END $$;

-- §2 Relay: nhận theo lô, mỗi sự kiện chỉ được nhận một lần, lần sau rỗng
DO $$
DECLARE i int; n1 int; n2 int; n3 int;
BEGIN
    FOR i IN 1..250 LOOP PERFORM place_order(100 + i, format('[{"product_id":%s,"category_id":%s,"qty":1,"amount":%s}]', i, 1 + i % 40, 10000 * (1 + i % 5))::jsonb, timestamptz '2026-10-10 10:00+07' + i * interval '1 minute'); END LOOP;
    SELECT count(*) INTO n1 FROM claim_outbox(100);
    SELECT count(*) INTO n2 FROM claim_outbox(1000);
    SELECT count(*) INTO n3 FROM claim_outbox(1000);
    ASSERT n1 = 100 AND n2 = 151 AND n3 = 0, format('claim: %s %s %s (kỳ vọng 100 151 0)', n1, n2, n3);   -- 251 sự kiện = 1 (§1) + 250
END $$;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT id FROM outbox WHERE published_at IS NULL ORDER BY id LIMIT 100 FOR UPDATE SKIP LOCKED;

-- §3 Consumer idempotent: phát lại cùng sự kiện nhiều lần (at-least-once) không làm sai tổng
DO $$
DECLARE ev record; r1 numeric; r2 numeric; applied int := 0; skipped int := 0; ok boolean;
BEGIN
    SELECT COALESCE(sum(revenue), 0) INTO r1 FROM daily_rollup WHERE day >= '2026-10-10';
    FOR ev IN SELECT id, payload FROM outbox WHERE aggregate_id > 0 ORDER BY id LOOP
        ok := apply_order_placed('rollup', ev.id, ev.payload); IF ok THEN applied := applied + 1; ELSE skipped := skipped + 1; END IF;
    END LOOP;
    FOR ev IN SELECT id, payload FROM outbox ORDER BY id LOOP                      -- phát lại TOÀN BỘ lần hai
        ok := apply_order_placed('rollup', ev.id, ev.payload); IF ok THEN applied := applied + 1; ELSE skipped := skipped + 1; END IF;
    END LOOP;
    SELECT sum(revenue) INTO r2 FROM daily_rollup WHERE day >= '2026-10-10';
    ASSERT applied = 251 AND skipped = 251, format('applied=%s skipped=%s', applied, skipped);
    ASSERT r2 - r1 = (SELECT sum((i->>'amount')::numeric) FROM outbox, jsonb_array_elements(payload->'items') i), 'rollup tăng đúng tổng amount, không nhân đôi';
END $$;

-- §4 Sự kiện đến trễ vào đúng NGÀY NGHIỆP VỤ (giờ VN), không phải ngày nhận
DO $$
DECLARE o bigint; before_rev numeric; after_rev numeric; ev record;
BEGIN
    SELECT revenue INTO before_rev FROM daily_rollup WHERE day = '2026-03-14' AND category_id = 9;
    -- 23:30 ngày 14/03 giờ VN = 16:30Z cùng ngày; 00:30 ngày 15/03 giờ VN = 17:30Z ngày 14/03 => phải vào ngày 15, không phải 14
    o := place_order(7, '[{"product_id":9,"category_id":9,"qty":1,"amount":777000}]', timestamptz '2026-03-14 23:30+07');
    SELECT id, payload INTO ev FROM outbox WHERE aggregate_id = o;
    PERFORM apply_order_placed('rollup', ev.id, ev.payload);
    SELECT revenue INTO after_rev FROM daily_rollup WHERE day = '2026-03-14' AND category_id = 9;
    ASSERT after_rev = before_rev + 777000, 'đơn 23:30 VN ngày 14 phải cộng vào ngày 14';
    o := place_order(7, '[{"product_id":9,"category_id":9,"qty":1,"amount":111000}]', timestamptz '2026-03-15 00:30+07');
    SELECT id, payload INTO ev FROM outbox WHERE aggregate_id = o;
    PERFORM apply_order_placed('rollup', ev.id, ev.payload);
    ASSERT (SELECT revenue FROM daily_rollup WHERE day = '2026-03-14' AND category_id = 9) = after_rev, 'đơn 00:30 VN ngày 15 không được cộng vào ngày 14 (dù vẫn là 17:30Z ngày 14)';
END $$;

-- §5 Phân tích: dashboard "doanh thu theo ngày x ngành hàng, 30 ngày" — quét fact vs đọc rollup
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT (sold_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, category_id, sum(amount)
FROM sales_fact WHERE sold_at >= timestamptz '2026-08-20' GROUP BY 1, 2;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT day, category_id, revenue FROM daily_rollup WHERE day >= date '2026-08-20';

-- §6 Materialized view (làm mới toàn bộ) cho kiểm tra chéo; CONCURRENTLY cần UNIQUE index
CREATE MATERIALIZED VIEW mv_daily AS
SELECT (sold_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, category_id, sum(amount) AS revenue
FROM sales_fact GROUP BY 1, 2;
CREATE UNIQUE INDEX mv_daily_uk ON mv_daily (day, category_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily;
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM mv_daily m JOIN daily_rollup r USING (day, category_id) WHERE m.revenue <> r.revenue) = 0, 'rollup tăng dần phải khớp mv làm mới toàn bộ';
    ASSERT (SELECT count(*) FROM mv_daily) = (SELECT count(*) FROM daily_rollup), 'cùng số nhóm';
END $$;

-- §7 Kích thước thực đo
SELECT relname, reltuples::bigint AS n, pg_size_pretty(pg_total_relation_size(oid)) AS total
FROM pg_class WHERE relnamespace = 'd09'::regnamespace AND relname IN ('sales_fact', 'daily_rollup', 'mv_daily', 'outbox', 'orders') ORDER BY relname;
