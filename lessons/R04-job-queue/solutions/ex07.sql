-- db: lab
-- mode: manual
-- Demo: trigger gửi NOTIFY mỗi khi có job mới (schema riêng r04n, không đụng r04). Cách tái hiện với 2 session: xem solutions/ex07.md.
DROP SCHEMA IF EXISTS r04n CASCADE;
CREATE SCHEMA r04n;
CREATE TABLE r04n.jobs (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, payload jsonb NOT NULL DEFAULT '{}');
CREATE FUNCTION r04n.notify_new_job() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_notify('r04n_jobs', NEW.id::text);
  RETURN NULL;
END $$;
CREATE TRIGGER jobs_notify AFTER INSERT ON r04n.jobs FOR EACH ROW EXECUTE FUNCTION r04n.notify_new_job();
INSERT INTO r04n.jobs DEFAULT VALUES;
