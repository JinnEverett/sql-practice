# D10 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Hiện tại | 1 primary 16 vCPU / 64 GB, 800 GB dữ liệu, 1 replica chưa dùng; 2k QPS (90% đọc), p99 80 ms; 300 connection trực tiếp từ app |
| Tăng 100× | 200k QPS đọc+ghi trộn, dữ liệu ~40 TB cuối năm 2; ghi 5k → 500k dòng/s sự kiện |
| Phân bố | 80% đọc rơi vào 1% khóa (Zipf); 70% dung lượng là bảng `events` append-only |
| Tính nhất quán | Đọc-ghi-của-chính-mình bắt buộc sau khi người dùng sửa hồ sơ; số liệu thống kê trễ vài phút được |
| Đội | 6 kỹ sư, chưa có DBA; ngân sách vận hành vừa phải |
| Ràng buộc | Một số truy vấn join nhiều bảng + giao dịch tài chính trên bảng `accounts` |

## Yêu cầu ngầm
1. **Đo trước khi scale**: top query (pg_stat_statements), cache hit, bloat, wait event. 80% vấn đề là truy vấn/index, không phải kiến trúc.
2. **Pooler** trước mọi thứ: `max_connections` mặc định 100, hiệu năng đạt đỉnh quanh số core.
3. **Replica ≠ miễn phí**: lag, read-your-writes, truy vấn trên replica bị hủy do xung đột.
4. **Cache**: hit-rate phụ thuộc phân bố truy cập; invalidation; thundering herd.
5. **Partition ≠ tăng tốc**: để bảo trì (xóa dữ liệu cũ), không phải để nhanh hơn.
6. **Shard**: chọn **khóa shard** quyết định mọi thứ; truy vấn không có khóa phải hỏi mọi shard; giao dịch xuyên shard mất tính nguyên tử; join/aggregate xuyên shard đắt.
7. **Khi nào rời Postgres**: phân tích (cột), tìm kiếm toàn văn quy mô lớn, KV/queue cực lớn, đồ thị, series thời gian. Không phải vì "Postgres chậm" mà vì mô hình truy cập khác.
8. **Lộ trình có thể đảo ngược** và có điều kiện kích hoạt bằng số.

## Câu hỏi phản biện
**B1** "100× của ai: người dùng, ghi, hay dữ liệu? Ba thứ đó cần ba lời giải khác nhau thế nào?" · "Có bao nhiêu thời gian? Có chấp nhận downtime khi chuyển không?"
**B2** "Cho tôi top 5 query và bảng nào chiếm bao nhiêu % dung lượng/IO."
**B3** "Một node làm được bao nhiêu TPS đọc/ghi, theo số đo của bạn? 200k QPS ở mức đó cần mấy node? Dữ liệu 40 TB có vừa một máy không, backup/restore mất bao lâu?"
**B4** "Bảng nào có thể partition theo thời gian? Bảng nào cần shard theo khóa nào? `accounts` có chuyển tiền giữa hai khóa không?"
**B5** "Truy vấn nào của bạn không có khóa shard? Cách xử lý (index toàn cục bằng bảng phụ, scatter-gather, tách sang hệ khác)?"
**B6** "Replica đọc: lag bao nhiêu thì người dùng thấy dữ liệu cũ? Cách đảm bảo read-your-writes?" · "Cache đặt ở đâu, hit-rate dự kiến bao nhiêu (dựa trên phân bố nào)? Cache chết thì sao?" · "PgBouncer transaction mode làm hỏng điều gì (session state, prepared statements, advisory lock)?"
**B7** "Thứ tự triển khai và điều kiện kích hoạt từng bậc? Bậc nào không thể quay lại?" · "Failover: RTO/RPO? Ai bị page lúc 3 giờ sáng?" · "Khi nào bạn nói 'đừng dùng Postgres cho cái này'?"

## Dấu hiệu đỏ
Nhảy thẳng tới sharding khi chưa đo gì · replica đọc mà không bàn lag · partition với kỳ vọng "nhanh hơn" · khóa shard là `created_at` hoặc auto-increment (hotspot) · giao dịch xuyên shard coi như vẫn nguyên tử · cache không có kế hoạch invalidation · không nhắc pooler.
