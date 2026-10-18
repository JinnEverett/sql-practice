-- db: lab
-- mode: check
-- reset
-- Giải thích: một ALTER TABLE cần khóa ACCESS EXCLUSIVE. Nếu có một truy vấn đang chạy (giữ ACCESS SHARE), ALTER phải CHỜ — và trong lúc nó chờ nó nằm trong hàng đợi khóa,
--   MỌI truy vấn đến sau (kể cả SELECT bình thường) xếp hàng sau nó. Một truy vấn báo cáo dài 5 phút + một ALTER = cả bảng đứng im 5 phút dù ALTER chưa chạy gì.
--   Cách phòng: đặt lock_timeout NGẮN (vài trăm ms) cho phiên migration; hết hạn thì ALTER bỏ chỗ (hàng đợi thông thoáng), thử lại sau một lát cho tới khi lọt được vào lúc không có ai giữ khóa.
--   SET LOCAL đặt trong vòng lặp (một sub-transaction bị rollback sẽ hoàn tác SET LOCAL), bắt lỗi lock_not_available (55P03), ngủ rồi thử lại, có giới hạn số lần.
-- Bẫy: ALTER trần (không lock_timeout): xếp hàng chặn cả bảng; lock_timeout dài (vài giây): vẫn chặn hàng đợi lâu; vòng lặp không giới hạn.
DO $$
DECLARE i int := 0;
BEGIN
  LOOP
    i := i + 1;
    BEGIN
      SET LOCAL lock_timeout = '200ms';
      ALTER TABLE r10.orders ADD COLUMN note text;
      EXIT;
    EXCEPTION WHEN lock_not_available THEN
      IF i >= 30 THEN RAISE; END IF;
      PERFORM pg_sleep(0.1);
    END;
  END LOOP;
END $$;
