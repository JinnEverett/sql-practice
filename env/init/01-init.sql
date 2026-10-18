-- Chạy MỘT LẦN khi volume còn trống (docker-entrypoint-initdb.d).
-- Tạo:
--   lab            sandbox cho bài tập, mỗi bài một schema riêng
--   shop_template  template có sẵn extension; mọi shop_* được tạo từ đây

CREATE DATABASE lab;
CREATE DATABASE shop_template;

\c shop_template
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION IF NOT EXISTS pg_prewarm;

\c lab
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION IF NOT EXISTS pg_prewarm;

\c postgres
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
ALTER DATABASE shop_template WITH IS_TEMPLATE true;
