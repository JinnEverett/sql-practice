-- D08 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql, bằng role quản trị (superuser); phần test RLS dùng SET ROLE.
SET search_path = d08;
SET client_min_messages = warning;

-- §0 Seed: 1000 tenant. Tenant 1 là "cá voi" (400k task, 500 project); tenant 2..1000 mỗi tenant ~600 task, 5 project
INSERT INTO tenants (name, plan) SELECT 'tenant-' || g, CASE WHEN g = 1 THEN 'enterprise' WHEN g % 10 = 0 THEN 'pro' ELSE 'free' END FROM generate_series(1, 1000) g;
INSERT INTO projects (tenant_id, name) SELECT 1, 'p' || g FROM generate_series(1, 500) g;
INSERT INTO projects (tenant_id, name) SELECT t, 'p' || g FROM generate_series(2, 1000) t, generate_series(1, 5) g;
INSERT INTO tasks (tenant_id, project_id, title, status, created_at)
SELECT 1, p.id, 'task ' || g, CASE WHEN g % 3 = 0 THEN 'done' ELSE 'open' END, timestamptz '2026-01-01' + g * interval '70 seconds'
FROM generate_series(1, 400000) g
JOIN LATERAL (SELECT id FROM projects WHERE tenant_id = 1 ORDER BY id OFFSET (g % 500) LIMIT 1) p ON true;
INSERT INTO tasks (tenant_id, project_id, title, status, created_at)
SELECT t, p.id, 'task ' || g, CASE WHEN g % 3 = 0 THEN 'done' ELSE 'open' END, timestamptz '2026-01-01' + g * interval '3 hours'
FROM generate_series(2, 1000) t, generate_series(1, 600) g
JOIN LATERAL (SELECT id FROM projects WHERE tenant_id = t ORDER BY id OFFSET (g % 5) LIMIT 1) p ON true;
ANALYZE;
SELECT (SELECT count(*) FROM tasks_t1) AS whale_rows, (SELECT count(*) FROM tasks_rest) AS rest_rows;

-- §1 Cách ly bằng RLS (role app, KHÔNG phải owner): thấy đúng tenant của mình, không thấy gì nếu quên đặt tenant (fail closed)
DO $$
DECLARE n_own bigint; n_none bigint; n_other bigint; hit int := 0; pid6 bigint;
BEGIN
    SELECT min(id) INTO pid6 FROM projects WHERE tenant_id = 6;                   -- lấy trước khi vào role app (RLS sẽ che project này)
    SET LOCAL ROLE d08_app;
    PERFORM set_config('app.tenant_id', '5', true);                              -- true = chỉ trong transaction này
    SELECT count(*) INTO n_own FROM tasks;
    SELECT count(*) INTO n_other FROM tasks WHERE tenant_id = 6;                  -- cố tình hỏi tenant khác
    PERFORM set_config('app.tenant_id', '', true);                                -- quên đặt tenant
    SELECT count(*) INTO n_none FROM tasks;
    ASSERT n_own = 600, format('tenant 5 phải thấy 600 task, thấy %s', n_own);
    ASSERT n_other = 0, 'không được thấy tenant khác dù WHERE tenant_id = 6';
    ASSERT n_none = 0, 'chưa đặt tenant thì không thấy gì';
    -- ghi chéo tenant bị WITH CHECK chặn
    PERFORM set_config('app.tenant_id', '5', true);
    BEGIN INSERT INTO tasks (tenant_id, project_id, title, status) VALUES (6, pid6, 'xâm nhập', 'open');
          hit := hit + 100;
    EXCEPTION WHEN insufficient_privilege THEN hit := hit + 1; END;                  -- 42501: new row violates row-level security policy
    RESET ROLE;
    ASSERT hit = 1, 'ghi chéo tenant phải bị chặn';
END $$;

-- §2 Khóa ngoại ghép chặn tham chiếu chéo tenant ngay cả với role quản trị (RLS không thấy được vì FK check bỏ qua RLS)
DO $$
DECLARE hit boolean := false;
BEGIN
    BEGIN INSERT INTO tasks (tenant_id, project_id, title, status) SELECT 5, id, 'sai tenant', 'open' FROM projects WHERE tenant_id = 6 LIMIT 1;
    EXCEPTION WHEN foreign_key_violation THEN hit := true; END;
    ASSERT hit, 'task của tenant 5 không được trỏ vào project của tenant 6';
END $$;

-- §3 BẪY connection pooling: set_config(..., false) / SET (phiên) rò sang request sau trên cùng connection. SET LOCAL thì không.
DO $$
DECLARE leaked text; local_after text;
BEGIN
    PERFORM set_config('app.tenant_id', '7', false);                   -- cách SAI trong transaction pooling
    leaked := current_setting('app.tenant_id');
    PERFORM set_config('app.tenant_id', '', false);
    PERFORM set_config('app.tenant_id', '8', true);                    -- cách ĐÚNG: hết hiệu lực khi transaction kết thúc
    ASSERT leaked = '7' AND current_setting('app.tenant_id') = '8', 'kiểm tra cơ chế set_config';
END $$;
-- Sau khối DO (transaction đã kết thúc) giá trị LOCAL phải biến mất:
SELECT current_setting('app.tenant_id', true) AS after_txn_should_be_empty;

-- §4 Chi phí RLS trên truy vấn nóng: đọc 20 task mới nhất của một tenant nhỏ (qua role app)
BEGIN;
SET LOCAL ROLE d08_app;
SELECT set_config('app.tenant_id', '500', true);
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id, title FROM tasks ORDER BY created_at DESC LIMIT 20;
ROLLBACK;
-- (đối chứng) cùng truy vấn bằng WHERE tenant_id tường minh, không RLS
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id, title FROM tasks WHERE tenant_id = 500 ORDER BY created_at DESC LIMIT 20;

-- §5 Dữ liệu lệch: cùng một câu lệnh, hai kế hoạch. Tenant nhỏ -> index; cá voi -> quét theo project/partition riêng
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT count(*) FROM tasks WHERE tenant_id = 500 AND status = 'open';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT count(*) FROM tasks WHERE tenant_id = 1 AND status = 'open';

-- §6 Noisy neighbor ở mức DB: truy vấn nặng của cá voi bị statement_timeout hủy chứ không giữ máy.
-- Trong schema.sql: ALTER ROLE d08_reports SET statement_timeout (áp dụng khi role ĐĂNG NHẬP). Ở đây dùng SET LOCAL để mô phỏng trong 1 phiên.
\set ON_ERROR_STOP off
BEGIN;
SET LOCAL ROLE d08_reports;
SET LOCAL statement_timeout = '150ms';
SELECT set_config('app.tenant_id', '1', true);
SELECT count(*) FROM tasks a JOIN tasks b ON b.project_id = a.project_id AND b.tenant_id = a.tenant_id;   -- join tự thân 400k dòng
\set heavy_sqlstate :SQLSTATE
ROLLBACK;
\set ON_ERROR_STOP on
SELECT (:'heavy_sqlstate' = '57014') AS cancelled_by_timeout \gset
\if :cancelled_by_timeout
\echo 'OK: truy vấn nặng bị hủy (57014 query_canceled)'
\else
\echo 'FAIL: truy vấn nặng không bị hủy'
SELECT 1/0;
\endif
-- truy vấn nhẹ của tenant nhỏ vẫn chạy bình thường dưới cùng role
BEGIN;
SET LOCAL ROLE d08_reports;
SET LOCAL statement_timeout = '150ms';
SELECT set_config('app.tenant_id', '500', true);
SELECT count(*) AS light_query_rows FROM tasks;
ROLLBACK;

-- §7 Xóa / di chuyển tenant lớn
-- (a) Nâng tenant 2 lên partition riêng, số dòng bảo toàn, truy vấn chỉ chạm partition mới
DO $$
DECLARE moved bigint;
BEGIN
    moved := promote_tenant(2);
    ASSERT moved = 600, format('chuyển %s dòng, kỳ vọng 600', moved);
    ASSERT (SELECT count(*) FROM tasks WHERE tenant_id = 2) = 600, 'đủ dòng sau khi chuyển';
    ASSERT (SELECT count(*) FROM tasks_rest WHERE tenant_id = 2) = 0, 'rest không còn tenant 2';
END $$;
EXPLAIN (COSTS OFF) SELECT count(*) FROM tasks WHERE tenant_id = 2;

-- (b) Xóa tenant cá voi: DETACH + DROP partition thay cho DELETE 400k dòng (DELETE thật được đo ở REFERENCE)
ALTER TABLE tasks DETACH PARTITION tasks_t1;
DROP TABLE tasks_t1;
DO $$ BEGIN ASSERT (SELECT count(*) FROM tasks WHERE tenant_id = 1) = 0, 'cá voi đã bị xóa'; END $$;

-- §8 Kích thước thực đo
SELECT relname, reltuples::bigint AS n, pg_size_pretty(pg_total_relation_size(oid)) AS total
FROM pg_class WHERE relnamespace = 'd08'::regnamespace AND relname IN ('tasks_rest', 'tasks_t2', 'projects', 'tenants') ORDER BY relname;
