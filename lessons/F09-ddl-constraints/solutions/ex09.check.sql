BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.rooms VALUES (1, 'Phòng A'), (2, 'Phòng B')$$), 'tạo 2 phòng');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.rooms VALUES (3, 'phòng a')$$, '23505'), 'tên phòng trùng khác hoa/thường bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'An', '2026-10-20 09:00+07', '2026-10-20 10:00+07')$$), 'đặt phòng A 9:00–10:00');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (2, 1, 'Bình', '2026-10-20 10:00+07', '2026-10-20 11:00+07')$$), 'lịch nối tiếp 10:00–11:00 được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (12, 1, 'Chi', '2026-10-20 09:30+07', '2026-10-20 10:30+07')$$, '23P01'), 'chồng giờ cùng phòng bị chặn (23P01)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (13, 1, 'Chi', '2026-10-20 08:00+07', '2026-10-20 12:00+07')$$, '23P01'), 'lịch bao trùm lịch khác bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (14, 2, 'Chi', '2026-10-20 09:30+07', '2026-10-20 10:30+07')$$), 'cùng giờ nhưng phòng khác: được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at, status) OVERRIDING SYSTEM VALUE VALUES (5, 1, 'Dũng', '2026-10-20 09:30+07', '2026-10-20 10:30+07', 'cancelled')$$), 'lịch đã hủy không bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE f09.bookings SET status = 'confirmed' WHERE id = 5$$, '23P01'), 'khôi phục lịch hủy đang chồng giờ: bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE f09.bookings SET status = 'cancelled' WHERE id = 1$$), 'hủy lịch 9:00–10:00');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (15, 1, 'Em', '2026-10-20 09:00+07', '2026-10-20 10:00+07')$$), 'sau khi hủy, người khác đặt lại khung đó được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (16, 1, 'X', '2026-10-21 12:00+07', '2026-10-21 12:00+07')$$, '23514'), 'ends_at = starts_at bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at, status) OVERRIDING SYSTEM VALUE VALUES (17, 1, 'X', '2026-10-22 12:00+07', '2026-10-22 13:00+07', 'pending')$$, '23514'), 'status lạ bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.bookings (id, room_id, booked_by, starts_at, ends_at) OVERRIDING SYSTEM VALUE VALUES (18, 99, 'X', '2026-10-22 12:00+07', '2026-10-22 13:00+07')$$, '23503'), 'phòng không tồn tại bị chặn');
ROLLBACK;
