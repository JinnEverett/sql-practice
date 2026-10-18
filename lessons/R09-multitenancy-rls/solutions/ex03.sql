-- db: lab
-- mode: check
-- reset
-- Giải thích: policy hiện có `tenant_id = current_setting('app.tenant_id')::int` VỠ trong hai tình huống: (1) biến phiên chưa từng được đặt → current_setting ném lỗi
--   "unrecognized configuration parameter" (42704) làm hỏng cả query; (2) biến đã đặt trong một transaction trước đó rồi RESET → giá trị còn là chuỗi rỗng '' và ép '' sang int báo lỗi 22P02.
--   Cả hai là lỗi, tuy an toàn (không lộ dữ liệu) nhưng là sự cố vận hành. Sửa: current_setting('app.tenant_id', true) (trả NULL nếu chưa đặt) và nullif(…, '') cho chuỗi rỗng;
--   so sánh với NULL không khớp dòng nào → trả 0 dòng, không lỗi ("fail closed").
-- Bẫy: chỉ thêm `true` mà quên nullif (vẫn lỗi với chuỗi rỗng); dùng coalesce(…, '0')::int (tenant 0 có thể tồn tại); DROP rồi tạo lại policy nhưng quên WITH CHECK ở policy ghi.
ALTER POLICY tenant_isolation ON r09.notes
  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
