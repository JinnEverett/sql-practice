# D02 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Chỉ "rút gọn + redirect" | Có quy mô, thiếu retention/hết hạn | Có QPS, p99, retention click, xử lý xóa/hết hạn, alias |
| Data model | `clicks` có FK + counter trong `links` | Tách `clicks` nhưng không partition | `links` hẹp, code UNIQUE, `clicks` append-only partition theo thời gian, rollup riêng |
| Index & query | Index theo `long_url` | Index theo code, không đo | Redirect = 1 index scan (đọc được buffers), partial index cho owner, nêu kích thước index vs RAM |
| Consistency & concurrency | Random + check-then-insert | Có UNIQUE + retry | Sinh code không va chạm (song ánh/sequence), rollup idempotent (ghi đè, không cộng dồn) |
| Scale & vận hành | Không ước lượng click | Có QPS, thiếu dung lượng | QPS + GB/tháng + retention bằng DROP PARTITION; cache hit-rate; kế hoạch shard theo code |
| Trade-off | Một phương án sinh ID | So sánh 2 | So sánh ≥ 3 (sequence+song ánh / random+retry / hash) với va chạm, enumerate, phụ thuộc DB |

**Trừ nặng:** counter trong bảng `links` cập nhật mỗi click (−3 Index & query hoặc Consistency).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: bit.ly/TinyURL dùng ID tuần tự (hoặc range ID cấp cho từng app server) rồi base62; click ghi qua log/stream (Kafka) rồi mới tổng hợp.
