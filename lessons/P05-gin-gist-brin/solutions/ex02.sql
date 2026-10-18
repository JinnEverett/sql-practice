-- db: shop_m
-- mode: check
-- Giải thích: events chỉ append nên created_at tăng theo vị trí vật lý → min/max mỗi nhóm 128 page là khoảng hẹp. BRIN chỉ 32 kB (B-tree 71 072 kB, nhỏ hơn 2 200×).
--   Truy vấn một ngày: Bitmap Heap Scan lossy 384 block, 390 buffers (Seq Scan 45 243), phải recheck và loại 9 702 dòng thừa — cái giá của độ chính xác thấp.
-- Bẫy: B-tree (đúng nhưng 71 MB); BRIN trên cột không tương quan (user_id) — planner bỏ qua.
CREATE INDEX ON events USING brin (created_at);
