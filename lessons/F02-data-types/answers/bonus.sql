-- Bonus · UUID lưu bằng text vs uuid ở 10M dòng
-- DỰ ĐOÁN (2026-10-12, trước khi đo):
--   1. text: 36 byte/giá trị · uuid: 20 byte/giá trị
--   2. Bảng tốn thêm: ~160 MB (= (36-20) × 10M)
--   3. Index tốn thêm: không biết

-- Bước 1 (người học viết): kết quả 40 | 16
SELECT
  pg_column_size('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::text) AS text_bytes,
  pg_column_size('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid) AS uuid_bytes;

-- ĐO THẬT (Claude dựng 2 bảng 1M dòng gen_random_uuid(), PK tạo trước rồi INSERT):
--   pg_column_size trên đĩa: text 37 · uuid 16
--   | đối tượng | text   | uuid   | chênh 1M | ×10 → 10M |
--   | bảng      | 65.1MB | 42.2MB | +22.9MB  | ~+229MB   |
--   | index PK  | 73.0MB | 38.4MB | +34.6MB  | ~+346MB   |
--   Tổng chênh ở 10M ≈ 575MB (dự đoán 160MB, mới tính cột, chưa tính index)
