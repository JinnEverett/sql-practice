-- db: lab
-- mode: check
-- reset
-- Giải thích: Nested Loop lặp phía trong theo số dòng ngoài K (mỗi lần dò PK của mid); chi phí ~ K × (vài page). Hash Join đọc cả mid một lần (~2 000 page) rồi dò: gần hằng. Giao điểm chi phí ~ K = 10 000–30 000.
--   Đo thật (ex ở README): buffers hòa ở K ≈ 3 000, thời gian hòa ở K ≈ 50 000 vì cache nóng làm mỗi lần dò index rẻ.
-- Bẫy: tin rằng Nested Loop luôn tệ ("N+1 trong SQL") hoặc Hash Join luôn tốt.
SELECT 'Nested Loop' AS k100, 'Nested Loop' AS k1000, 'Hash Join' AS k100000, 'Hash Join' AS k900000;
