-- Xóa dữ liệu tháng cũ nhất: DELETE trên bảng phẳng vs DETACH+DROP partition. Cần schema.sql + queries.sql đã chạy. Xem \timing.
SET search_path = d10;
SELECT count(*) AS rows_flat_aug FROM events_flat WHERE ts < '2026-09-01';
\timing on
DELETE FROM events_flat WHERE ts < '2026-09-01';
ALTER TABLE events DETACH PARTITION events_2026_08;
DROP TABLE events_2026_08;
\timing off
SELECT pg_size_pretty(pg_total_relation_size('events_flat')) AS flat_size_after_delete_before_vacuum;
