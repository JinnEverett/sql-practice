-- db: lab
-- mode: manual
-- Demo: ADD COLUMN có default hằng (tức thì) so với default volatile (rewrite) trên p10.t_m; dùng ROLLBACK để không đổi bảng.
BEGIN;
\timing on
ALTER TABLE p10.t_m ADD COLUMN x_const int DEFAULT 0;
ROLLBACK;
BEGIN;
ALTER TABLE p10.t_m ADD COLUMN x_vol double precision DEFAULT random();
ROLLBACK;
\timing off
