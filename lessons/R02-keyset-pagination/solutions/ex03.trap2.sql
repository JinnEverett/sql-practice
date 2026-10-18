-- sai: created_at <= ts → lặp lại id 105, 104 và 103 đã xem ở trang trước
SELECT id, created_at, title FROM r02.feed WHERE created_at <= '2026-01-01 00:20+00' ORDER BY created_at DESC, id DESC LIMIT 7;
