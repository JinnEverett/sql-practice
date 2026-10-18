-- Cách đúng khác: mốc nhỏ nhất vẫn đủ (96MB) viết bằng SET thường; vì chạy trong BEGIN…ROLLBACK nên không rò ra ngoài.
SET work_mem = '96MB';
