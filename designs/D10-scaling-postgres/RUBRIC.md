# D10 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Chấp nhận "tăng 100×" chung chung | Hỏi QPS, dung lượng | Tách đọc/ghi/dung lượng, phân bố truy cập, yêu cầu nhất quán, ngân sách, RTO/RPO, top query hiện tại |
| Data model | Giữ nguyên | Đề xuất partition | Phân loại bảng (append-only → partition thời gian; nóng → shard theo khóa; tham chiếu → nhân bản), chọn khóa shard có lý do |
| Index & query | Bỏ qua | Nhắc tối ưu | Tối ưu truy vấn/index trước (có bằng chứng EXPLAIN), hiểu partition không tăng tốc truy vấn, scatter-gather và bẫy FDW |
| Consistency & concurrency | Không nói | Biết lag | Read-your-writes có cơ chế (đọc primary / chờ LSN / remote_apply) + số đo; giao dịch xuyên shard (saga/2PC) nêu rõ cái mất |
| Scale & vận hành | Không có số | Có số ước lượng | Trần một node bằng số đo (connections → TPS), điều kiện kích hoạt từng bậc, failover, backup/restore, di chuyển không downtime |
| Trade-off | "Dùng X" | So sánh 2 | Lộ trình nhiều bậc với giá/lợi từng bậc, khi nào rời Postgres (và sang đâu), phương án thay thế (Citus/Vitess-like/NewSQL) |

**Trừ nặng:** shard khi chưa có số đo cho thấy cần (−3 Scale); khóa shard gây hotspot (−2 Data model); phớt lờ lag replica (−2 Consistency).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: Instagram/Notion/GitHub shard theo khóa nghiệp vụ sau khi đã vắt kiệt replica + cache + partition; đa số sản phẩm không bao giờ cần bậc shard.
