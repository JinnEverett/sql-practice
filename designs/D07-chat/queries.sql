-- D07 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d07;
SET client_min_messages = warning;

-- §0 Seed: 50k user, 20k hội thoại (80% DM, 20% nhóm 3–12 người), ~1.2M tin, độ dài hội thoại lệch
INSERT INTO users (handle) SELECT 'u' || g FROM generate_series(1, 50000) g;
INSERT INTO conversations (kind, last_seq, last_message_at)
SELECT CASE WHEN g % 5 = 0 THEN 'group' ELSE 'dm' END,
       1 + ((g * 7919) % 97) * ((g % 4) + 1) / 2,
       timestamptz '2026-10-01' + g * interval '40 seconds'
FROM generate_series(1, 20000) g;
INSERT INTO conversation_members (conversation_id, user_id, last_read_seq)
SELECT c.id, u.uid, (c.last_seq * ((u.uid * 31 + c.id) % 100) / 100)
FROM conversations c
CROSS JOIN LATERAL (
    SELECT DISTINCT 1 + ((c.id * 13 + k * 7919) % 50000) AS uid
    FROM generate_series(0, CASE WHEN c.kind = 'dm' THEN 1 ELSE 2 + (c.id % 10) END) k) u;
-- một user "bận rộn" (id 1) thuộc 800 hội thoại: ca xấu cho badge tổng và danh sách hội thoại
INSERT INTO conversation_members (conversation_id, user_id, last_read_seq)
SELECT c.id, 1, c.last_seq * (c.id % 7) / 10 FROM conversations c WHERE c.id <= 800 ON CONFLICT DO NOTHING;
INSERT INTO messages (conversation_id, seq, sender_id, client_msg_id, body, created_at)
SELECT c.id, s, m.user_id, gen_random_uuid(), 'tin ' || s, c.last_message_at - (c.last_seq - s) * interval '30 seconds'
FROM conversations c
CROSS JOIN LATERAL generate_series(1, c.last_seq) s
JOIN LATERAL (SELECT user_id FROM conversation_members cm WHERE cm.conversation_id = c.id ORDER BY user_id OFFSET (s % 2) LIMIT 1) m ON true;
ANALYZE;

-- §1 Bất biến seed: seq liên tục không lỗ, last_seq = max(seq)
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM (SELECT conversation_id FROM messages GROUP BY 1 HAVING count(*) <> max(seq) OR min(seq) <> 1) x) = 0, 'seq phải liên tục từ 1';
    ASSERT (SELECT count(*) FROM conversations c JOIN (SELECT conversation_id, max(seq) mx FROM messages GROUP BY 1) m ON m.conversation_id = c.id WHERE c.last_seq <> m.mx) = 0, 'last_seq lệch';
END $$;
SELECT (SELECT count(*) FROM messages) AS messages, (SELECT count(*) FROM conversation_members) AS member_rows, (SELECT max(last_seq) FROM conversations) AS longest_conv;

-- §2 A1 · gửi tin: idempotent, thứ tự theo seq, người ngoài không gửi được, đọc tin mình gửi là đã đọc
DO $$
DECLARE c bigint; u bigint; k uuid := gen_random_uuid(); r1 record; r2 record; hit boolean := false; before_seq bigint;
BEGIN
    SELECT conversation_id, user_id INTO c, u FROM conversation_members WHERE conversation_id = 4 LIMIT 1;
    SELECT last_seq INTO before_seq FROM conversations WHERE id = c;
    SELECT * INTO r1 FROM send_message(c, u, k, 'xin chào');
    SELECT * INTO r2 FROM send_message(c, u, k, 'xin chào');                       -- gửi lại cùng client_msg_id
    ASSERT r1.seq = before_seq + 1 AND r1.created AND r2.seq = r1.seq AND NOT r2.created, 'gửi lại phải trả tin cũ';
    ASSERT (SELECT last_read_seq FROM conversation_members WHERE conversation_id = c AND user_id = u) = r1.seq, 'người gửi đã đọc tin của mình';
    BEGIN PERFORM send_message(c, 49999999, gen_random_uuid(), 'xâm nhập'); EXCEPTION WHEN insufficient_privilege THEN hit := true; END;
    ASSERT hit, 'người ngoài không gửi được';
END $$;

-- §3 A2 · unread: badge từng hội thoại và tổng badge. Không đếm dòng messages.
SELECT 1 AS busy_user \gset
SELECT set_config('app.busy_user', :'busy_user', false);
SELECT :busy_user AS busy_user, count(*) AS conversations_of_user FROM conversation_members WHERE user_id = :busy_user;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT c.id, c.last_seq - m.last_read_seq AS unread
FROM conversation_members m JOIN conversations c ON c.id = m.conversation_id
WHERE m.user_id = :busy_user AND NOT m.muted AND c.last_seq > m.last_read_seq;

DO $$
DECLARE u bigint := current_setting('app.busy_user')::bigint; by_count bigint; by_seq bigint;
BEGIN
    SELECT sum(c.last_seq - m.last_read_seq) INTO by_seq FROM conversation_members m JOIN conversations c ON c.id = m.conversation_id WHERE m.user_id = u;
    SELECT count(*) INTO by_count FROM conversation_members m JOIN messages x ON x.conversation_id = m.conversation_id AND x.seq > m.last_read_seq WHERE m.user_id = u;
    ASSERT by_seq = by_count, format('unread bằng seq (%s) phải bằng unread đếm dòng (%s)', by_seq, by_count);
END $$;
-- (đối chứng) cách đếm dòng messages: đắt hơn nhiều khi hội thoại dài
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT count(*) FROM conversation_members m JOIN messages x ON x.conversation_id = m.conversation_id AND x.seq > m.last_read_seq WHERE m.user_id = :busy_user;

-- §4 mark_read đơn điệu + idempotent + chặn vượt last_seq
DO $$
DECLARE c bigint := 6; u bigint; a bigint; b bigint; d bigint; ls bigint;
BEGIN
    SELECT user_id INTO u FROM conversation_members WHERE conversation_id = c LIMIT 1;
    SELECT last_seq INTO ls FROM conversations WHERE id = c;
    a := mark_read(c, u, ls);
    b := mark_read(c, u, 1);                      -- đọc tới seq cũ: không được lùi
    d := mark_read(c, u, ls + 1000);              -- vượt: bị chặn ở last_seq
    ASSERT a = ls AND b = ls AND d = ls, format('mark_read sai: %s %s %s (last_seq %s)', a, b, d, ls);
END $$;

-- §5 A3 · lịch sử: trang mới nhất, rồi trang cũ hơn bằng keyset theo seq (hội thoại dài nhất)
SELECT id AS long_conv FROM conversations ORDER BY last_seq DESC, id LIMIT 1 \gset
SELECT set_config('app.long_conv', :'long_conv', false);
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT seq, sender_id, body, created_at FROM messages WHERE conversation_id = :long_conv ORDER BY seq DESC LIMIT 50;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT seq, sender_id, body, created_at FROM messages WHERE conversation_id = :long_conv AND seq < 100 ORDER BY seq DESC LIMIT 50;
DO $$
DECLARE p1 bigint[]; p2 bigint[]; lc bigint := current_setting('app.long_conv')::bigint;
BEGIN
    SELECT array_agg(seq ORDER BY seq DESC) INTO p1 FROM (SELECT seq FROM messages WHERE conversation_id = lc ORDER BY seq DESC LIMIT 50) x;
    SELECT array_agg(seq ORDER BY seq DESC) INTO p2 FROM (SELECT seq FROM messages WHERE conversation_id = lc AND seq < p1[50] ORDER BY seq DESC LIMIT 50) x;
    ASSERT p1[50] - 1 = p2[1], 'hai trang phải liền mạch không sót/không trùng';
END $$;

-- §6 A4 · danh sách hội thoại mới nhất của user (join, sort theo last_message_at; ổn khi user có vài trăm hội thoại)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT c.id, c.last_message_at, c.last_seq - m.last_read_seq AS unread
FROM conversation_members m JOIN conversations c ON c.id = m.conversation_id
WHERE m.user_id = :busy_user ORDER BY c.last_message_at DESC NULLS LAST LIMIT 20;

-- §7 Xóa mềm: tombstone giữ seq (không để lỗ trong chuỗi), body bị xóa thật
UPDATE messages SET body = NULL, deleted_at = now() WHERE conversation_id = 4 AND seq = 1;
DO $$ BEGIN ASSERT (SELECT body FROM messages WHERE conversation_id = 4 AND seq = 1) IS NULL, 'tombstone'; END $$;

-- §8 Kích thước thực đo
ANALYZE;
SELECT 'messages' rel, (SELECT count(*) FROM messages) n,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) total,
       round(sum(pg_total_relation_size(c.oid))::numeric / (SELECT count(*) FROM messages)) bytes_per_row
FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid WHERE i.inhparent = 'messages'::regclass
UNION ALL SELECT 'conversation_members', count(*), pg_size_pretty(pg_total_relation_size('conversation_members')), round(pg_total_relation_size('conversation_members')::numeric / count(*)) FROM conversation_members
UNION ALL SELECT 'conversations', count(*), pg_size_pretty(pg_total_relation_size('conversations')), round(pg_total_relation_size('conversations')::numeric / count(*)) FROM conversations;
