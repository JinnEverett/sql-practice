-- D07 · Chat: lưu tin nhắn, unread count, phân trang lịch sử. DB: lab, schema d07.
DROP SCHEMA IF EXISTS d07 CASCADE;
CREATE SCHEMA d07;
SET search_path = d07;

CREATE TABLE users (
    id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    handle text NOT NULL UNIQUE
);

-- Số thứ tự tin nhắn nằm TRONG hội thoại (seq = 1,2,3…), cấp bởi last_seq.
-- Lợi ích: thứ tự tổng trong hội thoại, unread = last_seq - last_read_seq (O(1)), phân trang theo seq.
-- Giá: cập nhật last_seq serialize mọi tin gửi vào CÙNG hội thoại (hot row theo hội thoại, không phải toàn hệ thống).
CREATE TABLE conversations (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kind            text NOT NULL CHECK (kind IN ('dm', 'group')),
    last_seq        bigint NOT NULL DEFAULT 0,
    last_message_at timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now()
) WITH (fillfactor = 70);

CREATE TABLE conversation_members (
    conversation_id bigint NOT NULL REFERENCES conversations(id),
    user_id         bigint NOT NULL REFERENCES users(id),
    last_read_seq   bigint NOT NULL DEFAULT 0,
    muted           boolean NOT NULL DEFAULT false,
    joined_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (conversation_id, user_id)
) WITH (fillfactor = 80);
CREATE INDEX members_user_idx ON conversation_members (user_id, conversation_id);     -- "các hội thoại của tôi"

-- Tin nhắn lưu MỘT lần cho cả nhóm (không mỗi người một bản). Hash partition theo conversation_id:
-- toàn bộ lịch sử một hội thoại nằm trong một partition; bảo trì/vacuum chia nhỏ được.
CREATE TABLE messages (
    conversation_id bigint NOT NULL,
    seq             bigint NOT NULL,
    sender_id       bigint NOT NULL,
    client_msg_id   uuid   NOT NULL,                      -- app sinh: gửi lại (mạng chập chờn) không tạo tin trùng
    body            text,                                 -- NULL = đã xóa (tombstone)
    created_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz,
    PRIMARY KEY (conversation_id, seq),
    CONSTRAINT messages_client_uk UNIQUE (conversation_id, sender_id, client_msg_id)
) PARTITION BY HASH (conversation_id);
CREATE TABLE messages_p0 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE messages_p1 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE messages_p2 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE messages_p3 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE messages_p4 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE messages_p5 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE messages_p6 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE messages_p7 PARTITION OF messages FOR VALUES WITH (MODULUS 8, REMAINDER 7);

-- Gửi tin: idempotent theo client_msg_id, chỉ thành viên mới gửi được. Trả (seq, đã_tạo_mới).
CREATE FUNCTION send_message(p_conv bigint, p_sender bigint, p_client uuid, p_body text)
RETURNS TABLE (seq bigint, created boolean) LANGUAGE plpgsql SET search_path = d07 AS $$
DECLARE v_seq bigint;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM conversation_members WHERE conversation_id = p_conv AND user_id = p_sender) THEN
        RAISE EXCEPTION 'user % không thuộc hội thoại %', p_sender, p_conv USING ERRCODE = 'insufficient_privilege';
    END IF;
    SELECT m.seq INTO v_seq FROM messages m WHERE m.conversation_id = p_conv AND m.sender_id = p_sender AND m.client_msg_id = p_client;
    IF FOUND THEN RETURN QUERY SELECT v_seq, false; RETURN; END IF;              -- gửi lại: trả tin cũ
    UPDATE conversations c SET last_seq = c.last_seq + 1, last_message_at = now() WHERE c.id = p_conv RETURNING c.last_seq INTO v_seq;
    INSERT INTO messages (conversation_id, seq, sender_id, client_msg_id, body) VALUES (p_conv, v_seq, p_sender, p_client, p_body);
    UPDATE conversation_members SET last_read_seq = v_seq WHERE conversation_id = p_conv AND user_id = p_sender;   -- tin của mình thì coi như đã đọc
    RETURN QUERY SELECT v_seq, true;
END $$;

-- Đánh dấu đã đọc: đơn điệu (không bao giờ lùi), idempotent, chặn vượt last_seq
CREATE FUNCTION mark_read(p_conv bigint, p_user bigint, p_upto bigint) RETURNS bigint LANGUAGE sql SET search_path = d07 AS $$
    UPDATE conversation_members m
    SET last_read_seq = GREATEST(m.last_read_seq, LEAST(p_upto, (SELECT last_seq FROM conversations WHERE id = p_conv)))
    WHERE m.conversation_id = p_conv AND m.user_id = p_user
    RETURNING m.last_read_seq $$;

-- Bảng thí nghiệm
CREATE TABLE demo_pool (conversation_id bigint, user_id bigint);
