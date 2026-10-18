-- db: lab
-- mode: check
-- reset
-- Giải thích: UPDATE hits không đổi cột có index nên đủ điều kiện HOT, nhưng page đầy 100% không có chỗ cho phiên bản mới
--   → phiên bản mới sang page khác (không HOT), mọi index (PK, label) phải thêm entry mới → index phình, bảng phình.
--   Hạ fillfactor để chừa chỗ, rồi CLUSTER (rewrite) để áp dụng cho cả page cũ. Fillfactor 70 chừa 30% ≈ 46 chỗ/page,
--   job chỉ sửa 10% số dòng nên đủ chỗ.
-- Bẫy: chỉ SET fillfactor mà không rewrite (page cũ vẫn đầy); VACUUM FULL không chạy được trong transaction nên check dùng CLUSTER.
ALTER TABLE p01.counters SET (fillfactor = 70);
CLUSTER p01.counters USING counters_pkey;
