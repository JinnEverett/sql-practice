-- Lần 1: discount_code <> 'VIP15', thiếu lọc tháng 9/2026 (194 | 5758710000.00)
-- Lần 2: sửa IS DISTINCT FROM, vẫn thiếu tháng (1735 | 48276153000.00). Đề sau đó được sửa cho rõ "trong tháng đó"
select count(*) as orders_count, sum(total_amount) as revenue from orders where discount_code is distinct from 'VIP15' and total_amount >= 10000000 and created_at >= '2026-09-01 00:00:00+07' and created_at < '2026-10-01 00:00:00+07';
