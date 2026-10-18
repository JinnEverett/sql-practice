-- Xóa một tenant 400k dòng: DELETE vs DETACH+DROP PARTITION. Cần prep_whales.sql đã chạy. Xem thời gian ở \timing.
SET search_path = d08;
\timing on
SELECT count(*) AS rows_before FROM tasks WHERE tenant_id = 9;
DELETE FROM tasks WHERE tenant_id = 9;                       -- cách 1: DELETE 400k dòng
ALTER TABLE tasks DETACH PARTITION tasks_t10;                -- cách 2: detach + drop
DROP TABLE tasks_t10;
\timing off
