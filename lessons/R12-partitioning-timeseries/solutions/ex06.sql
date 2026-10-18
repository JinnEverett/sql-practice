-- db: lab
-- mode: check
-- reset
-- Giải thích: gắn bảng có sẵn (legacy_events, dữ liệu tháng 7) làm partition mới KHÔNG phải copy dữ liệu: ATTACH PARTITION chỉ đổi catalog. Nhưng Postgres phải CHẮC mọi dòng nằm trong khoảng
--   [2026-07-01, 2026-08-01): nếu không chứng minh được bằng ràng buộc có sẵn, nó QUÉT cả bảng đó dưới khóa mạnh. Nếu bảng đã có CHECK (đã validate) suy ra được khoảng đó, nó bỏ qua bước quét.
--   Quy trình: (1) ADD CONSTRAINT CHECK (ts >= … AND ts < …) NOT VALID (ngắn) → (2) VALIDATE CONSTRAINT (quét, không chặn ghi) → (3) ATTACH PARTITION (nhanh nhờ CHECK) → (4) DROP CHECK thừa.
--   Cấu trúc cột và PK (id, ts) của bảng gắn vào phải khớp bảng cha (ở đây đã khớp).
-- Bẫy: ATTACH trực tiếp (quét bảng dưới ACCESS EXCLUSIVE, lâu với bảng lớn); khoảng của CHECK không khớp khoảng của ATTACH (vẫn quét); khoảng ATTACH chồng partition khác (lỗi 23514 hoặc 42P17).
ALTER TABLE r12.legacy_events ADD CONSTRAINT legacy_events_july CHECK (ts >= '2026-07-01 00:00+00' AND ts < '2026-08-01 00:00+00') NOT VALID;
ALTER TABLE r12.legacy_events VALIDATE CONSTRAINT legacy_events_july;
ALTER TABLE r12.events_p ATTACH PARTITION r12.legacy_events FOR VALUES FROM ('2026-07-01 00:00+00') TO ('2026-08-01 00:00+00');
ALTER TABLE r12.legacy_events DROP CONSTRAINT legacy_events_july;
