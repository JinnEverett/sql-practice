# S00 · Review (2026-10-07)

**Kết quả: ✅ đạt.** Hạ tầng chạy được, `bench` xuất được bảng so sánh xs/s/m.
Phần tự làm được 4/5 điểm: câu 1, 4, 5 đúng; câu 2, 3 thiếu ý. Không dùng gợi ý nào.

| Câu | Trả lời | Đúng/sai | Ghi chú |
|---|---|---|---|
| 1 | 4 DB `shop_*` | ✅ | `shop_xs`, `shop_s`, `shop_m`, `shop_template`. `shop_template` là khuôn để tạo các DB kia, không chứa dữ liệu. DB thật sự có dữ liệu chỉ có 3 |
| 2 | 7 bảng | ½ | Thiếu tên bảng: categories, events, order_items, orders, payments, products, users |
| 3 | `text` | ½ | Thiếu phần CHECK: `status` chỉ nhận `pending, paid, shipped, delivered, cancelled, refunded` |
| 4 | 42 dòng, id 1–8 không có parent | ✅ | Đó là 8 danh mục gốc (Thời trang, Điện tử… Thực phẩm). Cây 3 tầng |
| 5 | s ~2ms, m ~300ms, vì dữ liệu gấp 100 | ✅ | Đúng hướng. Phần giải thích sâu hơn ở dưới |

## Câu 5: vì sao chênh lệch (đo lại bằng `EXPLAIN (ANALYZE, BUFFERS)`)

| | shop_s | shop_m |
|---|---|---|
| Số dòng `events` | 32 363 | 3 238 808 (×100) |
| Dung lượng bảng | 3,6 MB = 452 page | 353 MB = 45 243 page (×100) |
| Plan | `Seq Scan` (1 tiến trình) | `Parallel Seq Scan` (3 tiến trình) |
| Page đọc từ cache Postgres | 452 (100%) | 2 256 (5%) |
| Page phải đọc từ OS/đĩa | 0 | 42 987 |
| Thời gian | ~3 ms | ~150–300 ms |

Ba điều rút ra:
1. **`count(*)` trong Postgres phải đọc hết cả bảng.** Postgres không lưu sẵn tổng số dòng, vì mỗi transaction có thể "thấy" một số dòng khác nhau (MVCC, học ở Tier I/R). Do đó chi phí tăng tuyến tính theo kích thước bảng, tức O(n).
2. **Bảng to hơn bộ nhớ đệm.** `shared_buffers` = 256MB, nhỏ hơn bảng 353MB. Phần lớn page phải lấy từ OS thay vì từ cache của Postgres.
3. **Postgres tự chia việc cho nhiều tiến trình.** Ở 1M, planner dùng `Parallel Seq Scan` với 2 worker. Nhờ vậy thời gian không tăng đủ 100 lần như kích thước dữ liệu.

## Nắm chắc
- Mở psql, chuyển DB bằng `\c`, xem bảng bằng `\dt`/`\d`, bật `\timing`.
- Đọc được kết quả một câu `SELECT` đơn giản.
- Có trực giác đúng: dữ liệu nhiều hơn thì thời gian chạy lâu hơn.

## Cần cải thiện
- **Đọc hết đề.** Câu 2 và câu 3 đều bỏ sót vế sau. Từ F01, mỗi bài yêu cầu cột, thứ tự và số dòng cụ thể; thiếu vế là sai.
- Kiểm tra mình đang ở DB nào (dấu nhắc `shop_m=#` hay `shop_s=#`) trước khi đọc số liệu. Trong buổi đã có lúc nhầm events shop_m thành shop_s.

## 📏 Dự đoán chờ kiểm chứng (đo khi sinh `shop_l`, trước Tier P)

`SELECT count(*) FROM events` trên shop_l (khoảng 32M dòng, khoảng 3,5 GB):

| Hỏi | Dự đoán của người học (2026-10-07) | Đo thật |
|---|---|---|
| Thời gian | 2–3 s (ngoại suy tuyến tính ×10 từ shop_m) | |
| % page nằm sẵn trong `shared_buffers` | gần như 0% ("sẽ không có trong shared buffer") | |
| Dự đoán thời gian có đổi khi bảng không vừa RAM của OS? | _chưa trả lời_ | |

## Ghi chú môi trường
- DBeaver lỗi `TimeZone "Asia/Saigon"`: chưa xử lý dứt điểm. Bản update DBeaver ghi đè `dbeaver.ini`. Có phương án sửa phía server (cài `tzdata-legacy`), chờ người học quyết.
