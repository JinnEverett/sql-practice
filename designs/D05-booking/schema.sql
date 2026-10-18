-- D05 · Booking: giữ chỗ tạm, hết hạn, chống double booking. DB: lab, schema d05.
-- Hai mô hình: (A) khoảng thời gian trên tài nguyên (phòng, bác sĩ) => EXCLUDE constraint; (B) ghế cố định => UPDATE có điều kiện.
DROP SCHEMA IF EXISTS d05 CASCADE;
CREATE SCHEMA d05;
SET search_path = d05;
CREATE EXTENSION IF NOT EXISTS btree_gist;       -- cho phép "resource_id WITH =" trong GiST (cần quyền tạo extension; env/init đã cài)

CREATE TABLE resources (
    id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    tz   text NOT NULL DEFAULT 'Asia/Ho_Chi_Minh'          -- múi giờ địa phương: ranh giới ngày/đêm tính theo đây
);

-- (A) Booking theo khoảng thời gian
CREATE TABLE bookings (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    resource_id     bigint NOT NULL REFERENCES resources(id),
    user_id         bigint NOT NULL,
    period          tstzrange NOT NULL CHECK (NOT isempty(period) AND lower_inc(period) AND NOT upper_inc(period)),   -- luôn [) => đặt liền kề không coi là chồng
    status          text NOT NULL CHECK (status IN ('held','confirmed','cancelled','expired')),
    hold_expires_at timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT held_has_expiry CHECK ((status = 'held') = (hold_expires_at IS NOT NULL)),
    -- Luật "không double booking" nằm trong DB: hai booking còn hiệu lực trên cùng tài nguyên không được chồng thời gian
    CONSTRAINT no_double_booking EXCLUDE USING gist (resource_id WITH =, period WITH &&)
        WHERE (status IN ('held', 'confirmed'))
);
CREATE INDEX bookings_user_idx ON bookings (user_id, created_at DESC);
-- Sweeper chỉ quan tâm hold còn sống: index nhỏ
CREATE INDEX bookings_hold_exp_idx ON bookings (hold_expires_at) WHERE status = 'held';

-- Giữ chỗ: trả id, hoặc NULL nếu khung giờ đã bị chiếm.
-- Hold quá hạn mà chưa ai dọn vẫn đang chiếm chỗ trong EXCLUDE (constraint không biết now()), nên "hết hạn lười" ngay lúc có người tranh.
CREATE FUNCTION hold_slot(p_res bigint, p_user bigint, p_period tstzrange, p_ttl interval DEFAULT interval '10 minutes')
RETURNS bigint LANGUAGE plpgsql SET search_path = d05 AS $$
DECLARE v bigint;
BEGIN
    UPDATE bookings SET status = 'expired', hold_expires_at = NULL
    WHERE resource_id = p_res AND status = 'held' AND hold_expires_at <= now() AND period && p_period;
    INSERT INTO bookings (resource_id, user_id, period, status, hold_expires_at)
    VALUES (p_res, p_user, p_period, 'held', now() + p_ttl) RETURNING id INTO v;
    RETURN v;
EXCEPTION WHEN exclusion_violation OR deadlock_detected THEN     -- 2 hold chồng nhau cùng lúc: một bên thua bằng exclusion_violation HOẶC bị chọn làm nạn nhân deadlock
    RETURN NULL;
END $$;

-- Xác nhận: chỉ chủ hold, chỉ khi chưa hết hạn. 0 dòng => hết hạn/không phải của bạn.
CREATE FUNCTION confirm_booking(p_id bigint, p_user bigint) RETURNS boolean
LANGUAGE plpgsql SET search_path = d05 AS $$
BEGIN
    UPDATE bookings SET status = 'confirmed', hold_expires_at = NULL
    WHERE id = p_id AND user_id = p_user AND status = 'held' AND hold_expires_at > now();
    RETURN FOUND;
END $$;

-- Sweeper nền: dọn theo lô, nhiều worker chạy song song không giẫm nhau
CREATE FUNCTION expire_holds(p_batch int DEFAULT 1000) RETURNS int
LANGUAGE sql SET search_path = d05 AS $$
    WITH due AS (
        SELECT id FROM bookings WHERE status = 'held' AND hold_expires_at <= now()
        ORDER BY hold_expires_at LIMIT p_batch FOR UPDATE SKIP LOCKED),
    u AS (UPDATE bookings b SET status = 'expired', hold_expires_at = NULL FROM due WHERE b.id = due.id RETURNING 1)
    SELECT count(*)::int FROM u $$;

-- (B) Ghế cố định: mỗi ghế một dòng, chiếm bằng UPDATE có điều kiện
CREATE TABLE seats (
    event_id   bigint   NOT NULL,
    seat_no    int      NOT NULL,
    status     text     NOT NULL DEFAULT 'free' CHECK (status IN ('free','held','sold')),
    held_by    bigint,
    hold_until timestamptz,
    PRIMARY KEY (event_id, seat_no),
    CONSTRAINT seat_hold_consistent CHECK ((status = 'held') = (held_by IS NOT NULL AND hold_until IS NOT NULL) OR status <> 'held')
) WITH (fillfactor = 70);

CREATE FUNCTION claim_seat(p_event bigint, p_seat int, p_user bigint, p_ttl interval DEFAULT interval '5 minutes') RETURNS boolean
LANGUAGE plpgsql SET search_path = d05 AS $$
BEGIN
    UPDATE seats SET status = 'held', held_by = p_user, hold_until = now() + p_ttl
    WHERE event_id = p_event AND seat_no = p_seat
      AND (status = 'free' OR (status = 'held' AND hold_until <= now()));        -- ghế trống, hoặc hold cũ đã hết hạn
    RETURN FOUND;
END $$;

CREATE FUNCTION buy_seat(p_event bigint, p_seat int, p_user bigint) RETURNS boolean
LANGUAGE plpgsql SET search_path = d05 AS $$
BEGIN
    UPDATE seats SET status = 'sold', hold_until = NULL
    WHERE event_id = p_event AND seat_no = p_seat AND status = 'held' AND held_by = p_user AND hold_until > now();
    RETURN FOUND;
END $$;

-- Bảng thí nghiệm "ngây thơ" (không constraint) cho pgbench
CREATE TABLE naive_bookings (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, resource_id bigint NOT NULL, period tstzrange NOT NULL);
