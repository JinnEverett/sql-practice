-- db: lab
-- mode: check
-- reset
-- Giải thích: đổi tên cột an toàn = expand/contract. Đổi tên trực tiếp (RENAME COLUMN) làm mọi phiên bản code cũ đang chạy lỗi ngay. Giai đoạn "expand":
--   cả cột cũ (total) và mới (amount_vnd) cùng tồn tại và luôn bằng nhau, bất kể code cũ ghi vào total hay code mới ghi vào amount_vnd. Trigger BEFORE INSERT OR UPDATE điền cột còn thiếu:
--   INSERT: cột nào có giá trị thì sao chép sang cột kia; UPDATE: cột nào bị đổi (khác OLD) thì kéo cột kia theo. Backfill các dòng đã có bằng một UPDATE (bảng nhỏ) — bảng lớn thì theo lô (ex03).
--   Sau khi mọi code đã chuyển sang cột mới: bỏ trigger, rồi DROP cột cũ ("contract").
-- Bẫy: trigger một chiều (code cũ ghi total thì amount_vnd cập nhật, code mới ghi amount_vnd thì total lệch); so sánh `<>` thay vì IS DISTINCT FROM làm hỏng với NULL; quên backfill dòng cũ.
CREATE FUNCTION r10.sync_amount() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.amount_vnd := coalesce(NEW.amount_vnd, NEW.total);
    NEW.total      := coalesce(NEW.total, NEW.amount_vnd);
  ELSIF NEW.total IS DISTINCT FROM OLD.total AND NEW.amount_vnd IS NOT DISTINCT FROM OLD.amount_vnd THEN
    NEW.amount_vnd := NEW.total;
  ELSIF NEW.amount_vnd IS DISTINCT FROM OLD.amount_vnd AND NEW.total IS NOT DISTINCT FROM OLD.total THEN
    NEW.total := NEW.amount_vnd;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER orders2_sync BEFORE INSERT OR UPDATE ON r10.orders2 FOR EACH ROW EXECUTE FUNCTION r10.sync_amount();
UPDATE r10.orders2 SET amount_vnd = total WHERE amount_vnd IS DISTINCT FROM total;
