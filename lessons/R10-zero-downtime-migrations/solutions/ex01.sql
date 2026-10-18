-- db: lab
-- mode: check
-- reset
-- Giải thích: từ Postgres 11, ADD COLUMN … DEFAULT <hằng> (hằng hoặc biểu thức IMMUTABLE/STABLE được tính MỘT lần) chỉ ghi giá trị mặc định vào catalog
--   (atthasmissing / attmissingval); các dòng cũ KHÔNG bị viết lại, đọc dòng cũ sẽ trả giá trị mặc định. Lệnh chỉ cần khóa ACCESS EXCLUSIVE trong tích tắc, bất kể bảng bao nhiêu dòng.
--   Cách cũ "ADD COLUMN (nullable) → UPDATE toàn bảng → SET NOT NULL" ghi lại mọi dòng (bloat, WAL, khóa lâu, replica lag).
-- Bẫy: DEFAULT volatile (random(), gen_random_uuid(), clock_timestamp()) bắt buộc viết lại cả bảng (mỗi dòng cần giá trị riêng) — phải dùng cách thêm cột + backfill theo lô (ex03).
ALTER TABLE r10.orders ADD COLUMN priority integer NOT NULL DEFAULT 0;
