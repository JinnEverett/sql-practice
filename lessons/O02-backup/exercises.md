# O02 · Bài tập (Backup)

Các bài thực hành bằng dòng lệnh: **`mode: manual`**, tự đối chiếu với `solutions/exNN.md` (có số đo thật). Dùng container `sql-practice-pg`; bài 1–4 và 7 cần `shop_m` (`bash datasets/shop/build.sh m` nếu chưa có); bài 5 dùng `pitr-lab.sh`.
Ghi lệnh đã chạy, thời gian và kích thước bạn đo được vào `answers/exNN.md`, sau đó mới đối chiếu. Số của bạn sẽ khác (máy khác), nhưng thứ tự lớn và kết luận phải khớp.

**Pass:** 6/7 bài, trong đó ex05 (PITR) làm ra kết quả thật.

---

## 🟢 Cơ bản

### ex01 · Ba định dạng dump
Dump `shop_m` ở dạng plain, custom và directory (`-j4`). Ghi thời gian và kích thước. Phần nào của thời gian là **nén**? Định dạng nào cho phép `pg_restore` chọn lọc, định dạng nào dump song song?

### ex02 · Đọc bản dump trước khi restore
Với file custom của ex01: xem danh mục (`pg_restore -l`) bao nhiêu mục; dump chỉ schema (`-s`) nặng bao nhiêu; dump riêng bảng `users`. Vì sao dump một bảng không đủ để restore độc lập?

---

## 🟡 Kết hợp

### ex03 · Restore vào database mới
Tạo DB trống, restore bằng `pg_restore` 1 luồng, rồi `-j4` vào DB khác. So thời gian; xác nhận `count(*)` của `orders`. Vì sao restore không thể nhanh bằng thời gian copy file?

### ex04 · Cứu đúng một bảng
`users` bị sửa nhầm. Từ bản dump, khôi phục **chỉ** bảng `users` sang DB tạm mà không restore cả DB. Vì sao không restore thẳng đè lên production?

---

## 🔴 Thực tế

### ex05 · "Dev xóa nhầm lúc 14:03"
Team báo: *"Dev chạy `DELETE FROM orders_demo WHERE id > 100` trên production, mất 299 900 dòng. Cần dữ liệu về lúc trước đó vài giây."* Dùng `bash lessons/O02-backup/pitr-lab.sh up | base | oops | restore "<T1>" | down` (nhớ `down` khi xong). Khôi phục bảng về 300 000 dòng. Giải thích vai trò của base backup, WAL archive, `restore_command`, `recovery_target_time`, `recovery_target_action`.

### ex06 · "Có backup nhưng chưa ai thử restore"
Kiểm toán hỏi: backup đêm qua có dùng được không? Chạy `pg_basebackup` + `pg_verifybackup` trên cluster `sql-practice-pg`, phá một byte rồi verify lại. Viết runbook kiểm thử restore định kỳ gồm: kiểm tra gì, bao lâu một lần, cảnh báo khi nào.

---

## 📏 ex07 · Câu hỏi quy mô: dữ liệu tăng 10×
Từ số đo `shop_m` (dump, restore, basebackup), **dự đoán** thời gian ở `shop_l` (≈ 9 GB, 10M đơn) cho từng việc và RPO/RTO của hai chiến lược (dump hằng đêm; base backup + WAL). Điều gì làm dự đoán tuyến tính sai? (Không bắt buộc sinh `shop_l`; nếu không đo thì nêu rõ là ước lượng.)
