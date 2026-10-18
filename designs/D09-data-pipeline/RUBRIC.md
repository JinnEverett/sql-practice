# D09 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | "Đẩy dữ liệu sang kho" | Hỏi độ tươi | Độ tươi, thứ tự, trùng/mất, múi giờ, sửa/hủy, ngân sách vận hành |
| Data model | Bảng sự kiện không khóa | Có `outbox` | `outbox` (aggregate, version UNIQUE, partial index chưa gửi), `processed_events`, fact + rollup, ngày nghiệp vụ |
| Index & query | Dashboard quét thô | Có rollup, không đo | So số đo thô vs rollup (buffers), BRIN + summarize, partial index outbox |
| Consistency & concurrency | Dual write | Outbox nhưng poll theo id | Outbox cùng transaction, `SKIP LOCKED`, consumer idempotent, thứ tự aggregate; **có thí nghiệm** mất sự kiện khi poll theo id |
| Scale & vận hành | Không nói CDC/slot | Biết CDC | Chi phí slot/WAL (có số đo), dọn outbox bằng partition, replica phân tích, backfill |
| Trade-off | Một kiến trúc | So sánh 2 | So sánh outbox-poll / CDC logical decoding / dual write; rollup tăng dần / MV refresh / kho riêng, với điều kiện chọn |

**Trừ nặng:** dual write hoặc poll `id > last_id` mà không thấy vấn đề (−3 Consistency); ngày theo UTC cho báo cáo VN (−1 Data model).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: outbox + Debezium → Kafka → consumer idempotent → kho cột (ClickHouse/BigQuery); aggregates tăng dần kiểu stream processing.
