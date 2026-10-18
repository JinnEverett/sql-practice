-- D05 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d05;
SET client_min_messages = warning;

-- §0 Seed: 2000 phòng, mỗi phòng 400 booking liền kề 2 giờ (800k booking), 90% confirmed / 10% cancelled
INSERT INTO resources (name) SELECT 'room-' || g FROM generate_series(1, 2000) g;
INSERT INTO bookings (resource_id, user_id, period, status)
SELECT r, 1 + (r * k) % 50000,
       tstzrange(timestamptz '2026-01-01' + k * interval '2 hours',
                 timestamptz '2026-01-01' + (k + 1) * interval '2 hours', '[)'),
       CASE WHEN (r + k) % 10 = 0 THEN 'cancelled' ELSE 'confirmed' END
FROM generate_series(1, 2000) r, generate_series(0, 399) k;
INSERT INTO seats SELECT 1, s FROM generate_series(1, 500) s;
ANALYZE;

-- §1 Constraint chặn chồng chéo; liền kề [) hợp lệ; cancelled không chiếm chỗ
DO $$
DECLARE hit int := 0; base timestamptz := timestamptz '2026-01-01';
BEGIN
    -- phòng 1, slot k=5 là [10h, 12h) của ngày 2026-01-01
    BEGIN
        INSERT INTO bookings (resource_id, user_id, period, status) VALUES (1, 1, tstzrange(base + interval '11 hours', base + interval '13 hours'), 'confirmed');
    EXCEPTION WHEN exclusion_violation THEN hit := hit + 1; END;                       -- chồng với slot đã confirmed
    BEGIN
        INSERT INTO bookings (resource_id, user_id, period, status) VALUES (1, 1, tstzrange(base, base + interval '1 hour'), 'confirmed');
    EXCEPTION WHEN exclusion_violation THEN hit := hit + 1; END;                       -- chồng slot đầu
    ASSERT hit = 2, 'chồng chéo phải bị chặn';
    -- phòng 1 slot k=0 (r+k)=1 không cancelled; slot k=9 (r=1) bị cancelled => đặt lại được
    INSERT INTO bookings (resource_id, user_id, period, status)
    SELECT resource_id, 7, period, 'confirmed' FROM bookings WHERE resource_id = 1 AND status = 'cancelled' LIMIT 1;
END $$;

-- §2 Hold -> confirm; hold thứ hai bị từ chối; hold hết hạn nhường chỗ ("hết hạn lười")
DO $$
DECLARE far timestamptz := timestamptz '2027-06-01 08:00+00'; h1 bigint; h2 bigint; h3 bigint;
BEGIN
    h1 := hold_slot(1, 100, tstzrange(far, far + interval '2 hours'));
    ASSERT h1 IS NOT NULL, 'hold đầu phải được';
    h2 := hold_slot(1, 101, tstzrange(far + interval '1 hour', far + interval '3 hours'));
    ASSERT h2 IS NULL, 'hold chồng phải bị từ chối';
    ASSERT NOT confirm_booking(h1, 999), 'người khác không xác nhận hộ được';
    UPDATE bookings SET hold_expires_at = now() - interval '1 second' WHERE id = h1;      -- giả lập hết hạn (chưa ai dọn)
    ASSERT NOT confirm_booking(h1, 100), 'hold hết hạn không xác nhận được';
    h3 := hold_slot(1, 101, tstzrange(far + interval '1 hour', far + interval '3 hours'));
    ASSERT h3 IS NOT NULL, 'hold hết hạn phải nhường chỗ cho người sau';
    ASSERT (SELECT status FROM bookings WHERE id = h1) = 'expired', 'hold cũ được đánh dấu expired';
    ASSERT confirm_booking(h3, 101), 'xác nhận hold còn hạn';
END $$;

-- §3 Sweeper nền
DO $$
DECLARE far timestamptz := timestamptz '2028-01-01'; n int;
BEGIN
    FOR i IN 0..9 LOOP PERFORM hold_slot(2, 200 + i, tstzrange(far + i * interval '3 hours', far + i * interval '3 hours' + interval '2 hours')); END LOOP;
    UPDATE bookings SET hold_expires_at = now() - interval '1 minute' WHERE resource_id = 2 AND status = 'held' AND period && tstzrange(far, far + interval '30 hours');
    n := expire_holds(1000);
    ASSERT n = 10, format('sweeper dọn %s/10', n);
    ASSERT expire_holds(1000) = 0, 'chạy lại không còn gì';
END $$;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id FROM bookings WHERE status = 'held' AND hold_expires_at <= now() ORDER BY hold_expires_at LIMIT 1000;

-- §4 A2 · "tài nguyên này có trống trong khung giờ này không" (GiST của EXCLUDE: resource_id = và period &&)
-- ✅ tham số kiểu bigint khớp operator class của btree_gist => cả hai cột nằm trong Index Cond
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT 1 FROM bookings
WHERE resource_id = 1234::bigint AND status IN ('held','confirmed') AND period && tstzrange('2026-01-10 10:00+00', '2026-01-10 12:00+00');
-- ⚠️ BẪY implicit cast: literal/tham số int4 so với cột bigint KHÔNG khớp operator của GiST (btree_gist) => resource_id thành Filter,
-- index chỉ lọc theo period => quét mọi phòng có booking giờ đó (mỗi phòng 1 dòng ⇒ ~2000 dòng/lần). Plan đo: xem Rows Removed by Filter.
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT 1 FROM bookings
WHERE resource_id = 1234 AND status IN ('held','confirmed') AND period && tstzrange('2026-01-10 10:00+00', '2026-01-10 12:00+00');

DO $$
DECLARE r1 bigint; r2 bigint;
BEGIN
    ASSERT (SELECT count(*) FROM bookings WHERE resource_id = 1234::bigint AND status IN ('held','confirmed')
            AND period && tstzrange('2026-01-10 10:00+00', '2026-01-10 12:00+00')) = 1, 'phòng 1234 bận lúc 10h-12h 10/01';
END $$;

-- Phòng trống trong 200 phòng đầu (anti-join). Mọi phòng đều có booking ở khung giờ này trừ các slot cancelled
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT r.id FROM resources r
WHERE r.id BETWEEN 1 AND 200 AND NOT EXISTS (
    SELECT 1 FROM bookings b WHERE b.resource_id = r.id AND b.status IN ('held','confirmed')
      AND b.period && tstzrange('2026-01-10 10:00+00', '2026-01-10 12:00+00'));
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM resources r WHERE r.id BETWEEN 1 AND 200 AND NOT EXISTS (
        SELECT 1 FROM bookings b WHERE b.resource_id = r.id AND b.status IN ('held','confirmed')
          AND b.period && tstzrange('2026-01-10 10:00+00', '2026-01-10 12:00+00'))) > 0, 'phải có phòng trống do slot cancelled';
END $$;

-- §5 Múi giờ: "đêm 14/03 giờ Việt Nam" là [14/03 00:00+07, 15/03 00:00+07) = [13/03 17:00Z, 14/03 17:00Z)
DO $$
DECLARE p tstzrange := tstzrange(timestamptz '2026-03-14 00:00 Asia/Ho_Chi_Minh', timestamptz '2026-03-15 00:00 Asia/Ho_Chi_Minh');
BEGIN
    ASSERT lower(p) = timestamptz '2026-03-13 17:00:00+00' AND upper(p) = timestamptz '2026-03-14 17:00:00+00', 'ranh giới ngày theo giờ VN';
END $$;

-- §6 (B) ghế: chiếm, chiếm trùng, hết hạn, mua
DO $$
DECLARE ok1 boolean; ok2 boolean; ok3 boolean;
BEGIN
    ok1 := claim_seat(1, 10, 1); ok2 := claim_seat(1, 10, 2);
    ASSERT ok1 AND NOT ok2, 'ghế chỉ một người giữ';
    ASSERT NOT buy_seat(1, 10, 2), 'người không giữ không mua được';
    UPDATE seats SET hold_until = now() - interval '1 second' WHERE event_id = 1 AND seat_no = 10;
    ASSERT NOT buy_seat(1, 10, 1), 'hold hết hạn không mua được';
    ok3 := claim_seat(1, 10, 2);
    ASSERT ok3, 'hold hết hạn phải nhường ghế';
    ASSERT buy_seat(1, 10, 2), 'người giữ hợp lệ mua được';
    ASSERT NOT claim_seat(1, 10, 3), 'ghế đã bán không giữ được nữa';
END $$;

-- §7 Kích thước thực đo
SELECT relname, reltuples::bigint n, pg_size_pretty(pg_total_relation_size(oid)) total,
       round(pg_total_relation_size(oid)::numeric / NULLIF(reltuples, 0)) bytes_per_row
FROM pg_class WHERE relnamespace = 'd05'::regnamespace AND relname IN ('bookings', 'seats');
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_index WHERE indrelid = 'bookings'::regclass ORDER BY 1::text;
