-- db: lab
-- mode: check
-- reset
-- Giải thích: sort 600 000 dòng (id, payload) tràn ra đĩa chỉ ~46 MB ở work_mem = 4MB, nhưng sort TRONG RAM cần ≈ 73 MB (quicksort Memory: 72628kB)
--   vì tuple trong bộ nhớ có thêm chi phí quản lý. Đo: 64MB vẫn "external merge", 96MB mới "quicksort". Chọn 128MB: đủ, có dư, và còn dưới trần 256MB.
--   Dùng SET LOCAL (hết hiệu lực khi COMMIT) cho truy vấn báo cáo, thay vì nâng work_mem toàn server: mỗi node × mỗi kết nối đều có thể xin chừng đó.
-- Bẫy: đoán bộ nhớ cần = dung lượng đĩa tạm (46 MB) rồi đặt 64MB: vẫn tràn; đặt 1GB cho chắc: vượt trần và nguy hiểm khi nhiều kết nối.
SET LOCAL work_mem = '128MB';
