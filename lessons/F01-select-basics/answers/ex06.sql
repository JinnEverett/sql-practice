select id, created_at, status, total_amount
from orders
where user_id = 1
order by created_at desc, id desc
limit 5 offset 10;

-- Bonus · DỰ ĐOÁN (ghi trước khi đo, 2026-10-08):
-- Trang 3 và trang 100 000 (toàn bộ orders trên shop_m, 5 đơn/trang, created_at DESC) chạy mất thời gian như nhau.
-- Lý do: đằng nào cũng chạy theo index; đồng thời cũng phải sort toàn bộ bảng trước rồi mới lấy.
