-- db: lab
-- mode: check
-- reset
-- Giải thích: double booking = hai đặt chỗ chồng khoảng thời gian trong cùng một phòng. "SELECT kiểm tra trống rồi INSERT" bị check-then-act (hai request đồng thời cùng thấy trống).
--   Giải pháp đúng là ràng buộc của database: EXCLUDE USING gist (room_id WITH =, during WITH &&) — không thể có hai dòng cùng phòng mà khoảng thời gian chồng nhau.
--   Dòng 'cancelled' không được chặn ai: thêm WHERE (status = 'confirmed') để ràng buộc là PARTIAL. Khoảng nửa mở [from, to) nên 9–10h và 10–11h liền kề không chồng.
--   Dưới đồng thời, INSERT thứ hai CHỜ INSERT đầu commit rồi mới báo lỗi 23P01 (exclusion_violation), nên không bao giờ cả hai cùng thành công.
--   Cần extension btree_gist để dùng `=` cho int trong GiST (đã có sẵn trong lab).
-- Bẫy: unique index trên (room_id, lower(during)) chỉ chặn trùng giờ bắt đầu, không chặn chồng 9:30–10:30; quên WHERE status → booking đã hủy cản trở đặt lại.
ALTER TABLE r08.bookings
  ADD CONSTRAINT bookings_no_overlap EXCLUDE USING gist (room_id WITH =, during WITH &&) WHERE (status = 'confirmed');
