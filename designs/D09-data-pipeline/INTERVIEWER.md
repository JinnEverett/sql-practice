# D09 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Quy mô | 2M đơn/ngày (≈ 23/s TB, ~300/s đỉnh); trung bình 2.5 dòng hàng/đơn; 20M sự kiện nghiệp vụ/ngày (đơn, thanh toán, vận chuyển) |
| Dashboard | Doanh thu theo ngày × ngành hàng × kênh; tươi ≤ 1 phút; xem được 2 năm |
| Consumer | Kho, email, tìm kiếm, kho dữ liệu; mỗi bên chịu được nhận trùng nhưng không chịu mất |
| Thứ tự | Quan trọng trong cùng một đơn (đặt → thanh toán → hủy); giữa các đơn không quan trọng |
| Múi giờ | Báo cáo theo giờ Việt Nam; server UTC |
| Sửa dữ liệu | Hủy/hoàn đơn phải trừ ngược doanh thu |
| Hạ tầng | Có Kafka; chưa có kho dữ liệu riêng; đội 3 kỹ sư |
| Ngân sách vận hành | Không muốn thêm hệ thống nặng nếu Postgres đủ |

## Yêu cầu ngầm
1. **Dual write**: ghi DB rồi publish Kafka trong cùng handler ⇒ mất hoặc phát nhầm khi một nửa hỏng ⇒ **outbox cùng transaction**.
2. **Poll theo `id > last_id` làm mất sự kiện**: id cấp lúc INSERT, commit không theo thứ tự id.
3. **At-least-once ⇒ consumer idempotent** (bảng đã xử lý / khóa tự nhiên).
4. **Thứ tự trong aggregate**: `aggregate_version` + bỏ qua bản cũ.
5. **Ngày nghiệp vụ theo múi giờ VN**, sự kiện đến trễ vào đúng ngày.
6. **CDC có giá**: slot không tiêu thụ giữ WAL đến khi đầy đĩa; `wal_level = logical`.
7. **Phân tích trên OLTP**: truy vấn quét lớn làm chậm đặt hàng; replica/kho riêng.
8. **BRIN cần summarize** sau khi nạp hàng loạt.
9. **Hủy/hoàn**: sự kiện bù trừ (âm), không UPDATE ngược.

## Câu hỏi phản biện
**B1** "Dashboard tươi bao nhiêu? 1 phút và 1 ngày dẫn tới hai kiến trúc khác nhau thế nào?" · "Consumer chịu trùng/mất/sai thứ tự đến đâu?"
**B2** "Liệt kê ghi (đặt đơn) và các đọc phân tích. Cái nào không được chạm primary?"
**B3** "20M sự kiện/ngày × 300 B = ? GB/ngày cho outbox nếu không dọn? 2.5 dòng/đơn × 2M × 365 = ? dòng fact/năm? Dashboard quét thô mất bao lâu ở quy mô đó, ngoại suy từ số đo?" (≈ 1.8B dòng fact/năm; quét 1M dòng đo ~8k buffers ⇒ 1.8B dòng ~15M buffers)
**B4** "Outbox có những cột nào? Vì sao `aggregate_version` + UNIQUE? Làm sao biết một sự kiện đã xử lý?" · "Fact lưu thời điểm nào: lúc đặt hay lúc nhận?"
**B5** "Relay lấy sự kiện kiểu gì để nhiều relay chạy song song? `id > last_id` có đúng không? Chứng minh bằng thí nghiệm." · "Index nào cho outbox? Vì sao partial?"
**B6** "CDC (Debezium) so với outbox-poll: ưu nhược? Chi phí vận hành khi consumer chết 3 ngày?" · "Rollup tăng dần hay `REFRESH MATERIALIZED VIEW`? Khi nào chọn cái nào?"
**B7** "Outbox lớn dần: dọn thế nào (partition + drop)? Bảng đã xử lý của consumer thì sao?" · "Backfill khi sai logic rollup?" · "x10 sự kiện thì thứ gì gãy: relay, consumer, outbox bloat, slot?"

## Dấu hiệu đỏ
Publish thẳng từ handler sau khi commit · poll theo `id > last_id` · consumer không idempotent · ngày theo UTC · `REFRESH MATERIALIZED VIEW` toàn bộ mỗi phút trên bảng tỉ dòng · slot replication không giám sát · phân tích chạy thẳng trên primary.
