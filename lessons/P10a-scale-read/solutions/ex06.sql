-- db: lab
-- mode: manual
-- Demo: đếm bao nhiêu page của t_m đang nằm trong shared_buffers (cần quyền superuser và extension pg_buffercache).
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
SELECT count(*) AS t_m_pages_in_cache FROM pg_buffercache b
WHERE b.relfilenode = pg_relation_filenode('p10.t_m'::regclass) AND b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database());
