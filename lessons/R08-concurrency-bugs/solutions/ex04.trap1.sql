-- sai: unique chỉ chặn trùng đúng giờ bắt đầu, không chặn chồng thời gian
CREATE UNIQUE INDEX bookings_no_dup ON r08.bookings (room_id, lower(during)) WHERE status = 'confirmed';
