-- D08 · Multi-tenant SaaS: isolation, noisy neighbor, migrate tenant lớn. DB: lab, schema d08.
-- Mô hình chọn: MỘT schema dùng chung, mọi bảng có tenant_id đứng đầu khóa; cách ly bằng RLS; tenant lớn tách partition riêng.
DROP SCHEMA IF EXISTS d08 CASCADE;
CREATE SCHEMA d08;
SET search_path = d08;

-- Role của ứng dụng: KHÔNG phải owner, KHÔNG superuser, KHÔNG BYPASSRLS => RLS có hiệu lực
DO $$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'd08_app') THEN CREATE ROLE d08_app NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'd08_reports') THEN CREATE ROLE d08_reports NOLOGIN; END IF;
END $$;
GRANT USAGE ON SCHEMA d08 TO d08_app, d08_reports;
-- Báo cáo nặng chạy bằng role riêng, bị giới hạn thời gian ở mức DB: một tenant không giữ máy hàng phút
ALTER ROLE d08_reports SET statement_timeout = '150ms';        -- (giá trị nhỏ để demo; thực tế vài chục giây)

CREATE TABLE tenants (
    id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name   text NOT NULL,
    plan   text NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'enterprise')),
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleting'))
);

-- Khóa cha có tenant_id => khóa ngoại ghép (tenant_id, project_id) chặn tham chiếu chéo tenant NGAY Ở DB
CREATE TABLE projects (
    tenant_id bigint NOT NULL REFERENCES tenants(id),
    id        bigint GENERATED ALWAYS AS IDENTITY,
    name      text NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

CREATE TABLE tasks (
    tenant_id  bigint NOT NULL,
    id         bigint GENERATED ALWAYS AS IDENTITY,
    project_id bigint NOT NULL,
    title      text NOT NULL,
    status     text NOT NULL CHECK (status IN ('open', 'done')),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, id),
    FOREIGN KEY (tenant_id, project_id) REFERENCES projects (tenant_id, id)
) PARTITION BY LIST (tenant_id);
-- Tenant khổng lồ (id 1) có partition riêng: cô lập vật lý, xóa/di chuyển rẻ. Mọi tenant còn lại vào DEFAULT.
CREATE TABLE tasks_t1   PARTITION OF tasks FOR VALUES IN (1);
CREATE TABLE tasks_rest PARTITION OF tasks DEFAULT;
CREATE INDEX tasks_project_idx ON tasks (tenant_id, project_id, status);
CREATE INDEX tasks_recent_idx  ON tasks (tenant_id, created_at DESC);

-- RLS: policy dùng tenant_id lấy từ biến phiên. current_setting(…, true) trả NULL nếu chưa đặt => KHÔNG thấy gì (fail closed)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;  ALTER TABLE projects FORCE ROW LEVEL SECURITY;
ALTER TABLE tasks    ENABLE ROW LEVEL SECURITY;  ALTER TABLE tasks    FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON projects
    USING      (tenant_id = (SELECT nullif(current_setting('app.tenant_id', true), '')::bigint))
    WITH CHECK (tenant_id = (SELECT nullif(current_setting('app.tenant_id', true), '')::bigint));
CREATE POLICY tenant_isolation ON tasks
    USING      (tenant_id = (SELECT nullif(current_setting('app.tenant_id', true), '')::bigint))
    WITH CHECK (tenant_id = (SELECT nullif(current_setting('app.tenant_id', true), '')::bigint));
GRANT SELECT, INSERT, UPDATE, DELETE ON projects, tasks TO d08_app, d08_reports;
GRANT SELECT ON tenants TO d08_app, d08_reports;

-- Nâng tenant lên partition riêng (di chuyển tenant lớn): chạy trong 1 transaction, chặn ghi tenant đó trong lúc chuyển.
-- Trả số dòng đã chuyển. Cần quyền owner (chạy bằng role quản trị, không phải d08_app).
CREATE FUNCTION promote_tenant(p_tenant bigint) RETURNS bigint LANGUAGE plpgsql SET search_path = d08 AS $$
DECLARE n bigint; part text := format('tasks_t%s', p_tenant);
BEGIN
    EXECUTE format('CREATE TABLE %I (LIKE tasks INCLUDING DEFAULTS INCLUDING CONSTRAINTS)', part);
    EXECUTE format('INSERT INTO %I SELECT * FROM tasks_rest WHERE tenant_id = %L', part, p_tenant);
    GET DIAGNOSTICS n = ROW_COUNT;
    EXECUTE format('DELETE FROM tasks_rest WHERE tenant_id = %L', p_tenant);
    EXECUTE format('ALTER TABLE tasks ATTACH PARTITION %I FOR VALUES IN (%L)', part, p_tenant);
    RETURN n;
END $$;
