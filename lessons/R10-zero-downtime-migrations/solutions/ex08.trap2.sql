-- sai: có lock_timeout nhưng quá dài và chỉ thử một lần — hàng đợi bị chặn gần 2 giây
SET lock_timeout = '3s';
ALTER TABLE r10.orders ADD COLUMN note text;
RESET lock_timeout;
