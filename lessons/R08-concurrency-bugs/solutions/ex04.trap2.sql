-- sai: quên điều kiện status → đặt chỗ đã hủy vẫn cản trở người khác (và cả bản ghi hủy trùng giờ bị chặn)
ALTER TABLE r08.bookings ADD CONSTRAINT bookings_no_overlap EXCLUDE USING gist (room_id WITH =, during WITH &&);
