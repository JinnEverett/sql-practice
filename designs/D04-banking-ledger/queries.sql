-- D04 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d04;
SET client_min_messages = warning;

-- §0 Seed: 50k tài khoản khách (id 2..50001) + tài khoản hệ thống (id 1, được âm), 50k funding + 200k chuyển tiền
INSERT INTO accounts (owner_ref) SELECT NULL FROM generate_series(1, 1);
INSERT INTO accounts (owner_ref) SELECT 'cust-' || g FROM generate_series(1, 50000) g;
INSERT INTO transactions (id, idempotency_key, request_hash, kind, created_at)
SELECT g, 'seed-' || g, '-', CASE WHEN g <= 50000 THEN 'funding' ELSE 'transfer' END,
       timestamptz '2026-10-01' + g * interval '10 seconds'
FROM generate_series(1, 250000) g;
WITH raw AS (
    SELECT g AS txn_id, 1 + g AS account_id, 100000000::bigint AS amount FROM generate_series(1, 50000) g
    UNION ALL SELECT g, 1, -100000000 FROM generate_series(1, 50000) g
    UNION ALL SELECT g, 2 + (g * 7) % 50000, -1000::bigint * (1 + g % 50) FROM generate_series(50001, 250000) g
    UNION ALL SELECT g, 2 + (g * 7 + 1 + g % 49999) % 50000, 1000::bigint * (1 + g % 50) FROM generate_series(50001, 250000) g
), run AS (
    SELECT txn_id, account_id, amount,
           sum(amount) OVER (PARTITION BY account_id ORDER BY txn_id, amount) AS bal
    FROM raw)
INSERT INTO entries (txn_id, account_id, amount, balance_after, created_at)
SELECT r.txn_id, r.account_id, r.amount, r.bal, t.created_at
FROM run r JOIN transactions t ON t.id = r.txn_id ORDER BY r.txn_id;
INSERT INTO account_balances (account_id, balance, allow_negative)
SELECT account_id, sum(amount), account_id = 1 FROM entries GROUP BY account_id;
SELECT setval(pg_get_serial_sequence('d04.transactions', 'id'), 250000);
ANALYZE;

-- §1 Bất biến toàn cục của sổ cái (seed phải thỏa trước khi thử nghiệm gì)
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM (SELECT txn_id FROM entries GROUP BY txn_id HAVING sum(amount) <> 0) x) = 0, 'có giao dịch không cân';
    ASSERT (SELECT sum(balance) FROM account_balances) = 0, 'tổng số dư toàn hệ thống phải bằng 0 (tiền không tự sinh)';
    ASSERT (SELECT count(*) FROM account_balances b
            JOIN (SELECT account_id, sum(amount) s FROM entries GROUP BY 1) e USING (account_id) WHERE b.balance <> e.s) = 0,
           'balance lệch sum(entries)';
END $$;

-- §2 A1 · chuyển tiền: idempotent, cùng key khác nội dung bị từ chối, thấu chi bị chặn
DO $$
DECLARE t1 bigint; t2 bigint; b_from bigint; b_to bigint; hit int := 0;
BEGIN
    SELECT balance INTO b_from FROM account_balances WHERE account_id = 10;
    SELECT balance INTO b_to   FROM account_balances WHERE account_id = 11;
    t1 := transfer('pay-1', 10, 11, 5000);
    t2 := transfer('pay-1', 10, 11, 5000);                         -- retry
    ASSERT t1 = t2, 'retry phải trả cùng giao dịch';
    ASSERT (SELECT balance FROM account_balances WHERE account_id = 10) = b_from - 5000, 'trừ đúng 1 lần';
    ASSERT (SELECT balance FROM account_balances WHERE account_id = 11) = b_to + 5000, 'cộng đúng 1 lần';
    BEGIN PERFORM transfer('pay-1', 10, 11, 9999); EXCEPTION WHEN unique_violation THEN hit := hit + 1; END;   -- cùng key khác số tiền
    BEGIN PERFORM transfer('pay-2', 10, 11, 1000000000000); EXCEPTION WHEN check_violation THEN hit := hit + 1; END;  -- thấu chi
    BEGIN PERFORM transfer('pay-3', 10, 10, 1); EXCEPTION WHEN invalid_parameter_value THEN hit := hit + 1; END;      -- tự chuyển
    ASSERT hit = 3, format('chỉ %s/3 lỗi mong đợi', hit);
    ASSERT NOT EXISTS (SELECT 1 FROM transactions WHERE idempotency_key IN ('pay-2', 'pay-3')), 'giao dịch lỗi phải rollback';
END $$;

-- §3 Sổ cái bất biến
DO $$
DECLARE hit int := 0;
BEGIN
    BEGIN UPDATE entries SET amount = 1 WHERE txn_id = 1; EXCEPTION WHEN restrict_violation THEN hit := hit + 1; END;
    BEGIN DELETE FROM entries WHERE txn_id = 1;            EXCEPTION WHEN restrict_violation THEN hit := hit + 1; END;
    ASSERT hit = 2, 'entries phải append-only';
END $$;

-- §4 Giao dịch không cân bị chặn ở COMMIT (ở đây ép kiểm ngay bằng SET CONSTRAINTS)
DO $$
DECLARE hit boolean := false; t bigint;
BEGIN
    BEGIN
        INSERT INTO transactions (idempotency_key, request_hash, kind) VALUES ('bad-1', '-', 'transfer') RETURNING id INTO t;
        INSERT INTO entries (txn_id, account_id, amount, balance_after) VALUES (t, 10, 100, 0);   -- chỉ một chân
        SET CONSTRAINTS ALL IMMEDIATE;
    EXCEPTION WHEN check_violation THEN hit := true; END;
    ASSERT hit, 'giao dịch một chân phải bị từ chối';
END $$;

-- §5 Hoàn tiền = giao dịch bù trừ, chỉ một lần
DO $$
DECLARE t bigint; r bigint; b0 bigint; b1 bigint; hit boolean := false;
BEGIN
    SELECT balance INTO b0 FROM account_balances WHERE account_id = 20;
    t := transfer('pay-rev', 20, 21, 7000);
    r := reverse_transfer('rev-1', t);
    SELECT balance INTO b1 FROM account_balances WHERE account_id = 20;
    ASSERT b0 = b1, 'hoàn xong số dư phải về như cũ';
    BEGIN PERFORM reverse_transfer('rev-2', t); EXCEPTION WHEN unique_violation THEN hit := true; END;
    ASSERT hit, 'hoàn lần hai phải bị chặn';
    ASSERT (SELECT count(*) FROM entries WHERE txn_id IN (t, r)) = 4, 'lịch sử giữ nguyên, thêm 2 dòng bù trừ';
END $$;

-- §6 A2 · sao kê có phân trang keyset (không OFFSET): trang 1 rồi trang 2 từ dòng cuối trang 1
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id, txn_id, amount, balance_after, created_at FROM entries
WHERE account_id = 12345 ORDER BY created_at DESC, id DESC LIMIT 20;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id, txn_id, amount, balance_after, created_at FROM entries
WHERE account_id = 12345 AND (created_at, id) < (timestamptz '2026-10-20', 9223372036854775807)
ORDER BY created_at DESC, id DESC LIMIT 20;

-- §7 A3 · số dư tại thời điểm T (không cần cộng dồn): entry cuối cùng trước T
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT balance_after FROM entries WHERE account_id = 12345 AND created_at < timestamptz '2026-10-15'
ORDER BY created_at DESC, id DESC LIMIT 1;

-- §8 A4 · đối soát với sao kê ngân hàng: lệch số tiền, thiếu bên ngân hàng, thừa bên ngân hàng
INSERT INTO bank_statement (ref, amount, value_date)
SELECT txn_id::text, amount, '2026-10-30'
FROM entries WHERE txn_id BETWEEN 60001 AND 61000 AND amount > 0;                 -- 1000 giao dịch khớp
UPDATE bank_statement SET amount = amount + 1 WHERE ref = '60010';                 -- lệch 1 đồng
DELETE FROM bank_statement WHERE ref = '60020';                                    -- ngân hàng thiếu
INSERT INTO bank_statement VALUES ('999999', 5000, '2026-10-30');                  -- ngân hàng thừa
WITH ledger AS (SELECT txn_id::text AS ref, amount FROM entries WHERE txn_id BETWEEN 60001 AND 61000 AND amount > 0),
     diff AS (
         SELECT COALESCE(l.ref, b.ref) AS ref, l.amount AS ledger_amt, b.amount AS bank_amt,
                CASE WHEN l.ref IS NULL THEN 'chỉ ở ngân hàng' WHEN b.ref IS NULL THEN 'chỉ ở sổ cái' ELSE 'lệch số tiền' END AS loai
         FROM ledger l FULL JOIN bank_statement b ON b.ref = l.ref
         WHERE l.ref IS NULL OR b.ref IS NULL OR l.amount <> b.amount)
SELECT * FROM diff ORDER BY ref;
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM (
        SELECT 1 FROM (SELECT txn_id::text ref, amount FROM entries WHERE txn_id BETWEEN 60001 AND 61000 AND amount > 0) l
        FULL JOIN bank_statement b ON b.ref = l.ref WHERE l.ref IS NULL OR b.ref IS NULL OR l.amount <> b.amount) x) = 3,
        'đối soát phải thấy đúng 3 chênh lệch';
END $$;

-- §9 Kích thước thực đo
SELECT 'entries' rel, (SELECT count(*) FROM entries) n,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) total,
       round(sum(pg_total_relation_size(c.oid))::numeric / (SELECT count(*) FROM entries)) bytes_per_row
FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid WHERE i.inhparent = 'entries'::regclass
UNION ALL SELECT 'transactions', count(*), pg_size_pretty(pg_total_relation_size('transactions')),
       round(pg_total_relation_size('transactions')::numeric / count(*)) FROM transactions
UNION ALL SELECT 'account_balances', count(*), pg_size_pretty(pg_total_relation_size('account_balances')),
       round(pg_total_relation_size('account_balances')::numeric / count(*)) FROM account_balances;
