-- R04 · hàng đợi job trong Postgres. Chạy trên DB `lab`. Chạy lại được nhiều lần.
-- Thời gian trong bảng tính tương đối theo now() lúc chạy setup (script chấm chạy setup ngay trước khi chấm).
DROP SCHEMA IF EXISTS r04 CASCADE;
CREATE SCHEMA r04;

CREATE TABLE r04.jobs (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  payload      jsonb NOT NULL DEFAULT '{}',
  priority     int NOT NULL DEFAULT 0,                    -- càng lớn càng ưu tiên
  status       text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'running', 'done', 'dead')),
  attempts     int NOT NULL DEFAULT 0,                    -- số lần đã được nhận xử lý
  max_attempts int NOT NULL DEFAULT 3,
  run_at       timestamptz NOT NULL DEFAULT now(),        -- không được nhận trước thời điểm này (hẹn giờ / backoff)
  locked_at    timestamptz,
  locked_by    text,
  last_error   text
);

INSERT INTO r04.jobs (priority, status, attempts, max_attempts, run_at, locked_at, locked_by) VALUES
  (0, 'queued',  0, 3, now() - interval '10 minutes', NULL, NULL),                          -- 1
  (5, 'queued',  0, 3, now() - interval '5 minutes',  NULL, NULL),                          -- 2
  (5, 'queued',  0, 3, now() - interval '20 minutes', NULL, NULL),                          -- 3  (ưu tiên 5, sớm hơn job 2)
  (9, 'queued',  0, 3, now() + interval '1 hour',     NULL, NULL),                          -- 4  (hẹn giờ trong tương lai)
  (1, 'running', 1, 3, now() - interval '30 minutes', now() - interval '1 minute',  'w9'),  -- 5  (đang chạy, mới nhận)
  (0, 'done',    1, 3, now() - interval '1 hour',     NULL, NULL),                          -- 6
  (3, 'queued',  0, 3, now() - interval '1 minute',   NULL, NULL),                          -- 7
  (0, 'queued',  0, 3, now() - interval '30 minutes', NULL, NULL),                          -- 8
  (1, 'running', 3, 3, now() - interval '30 minutes', now() - interval '2 minutes', 'w8'),  -- 9  (đang chạy, đã dùng hết lượt thử)
  (1, 'running', 1, 3, now() - interval '2 hours',    now() - interval '30 minutes','w7'),  -- 10 (treo: worker đã chết)
  (1, 'running', 3, 3, now() - interval '2 hours',    now() - interval '45 minutes','w6');  -- 11 (treo và đã hết lượt thử)

-- Bảng ghi nhận job nào được worker nào xử lý (dùng trong bộ chấm)
CREATE TABLE r04.log (job_id bigint NOT NULL, worker text NOT NULL, at timestamptz NOT NULL DEFAULT clock_timestamp());
