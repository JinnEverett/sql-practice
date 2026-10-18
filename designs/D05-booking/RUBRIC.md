# D05 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Không phân biệt loại tài nguyên | Có hold + hủy | + TTL, múi giờ/DST, liền kề, đổi lịch, tải mở bán bằng số |
| Data model | start/end hai cột, không ràng buộc | `tstzrange` nhưng chỉ UNIQUE(resource,start) | `tstzrange [)` + EXCLUDE GiST (partial theo status) + CHECK tính nhất quán `held`↔`hold_expires_at`; ghế: PK + trạng thái |
| Index & query | Quét tuần tự tìm chỗ trống | Có index, không đọc plan | Dùng chính GiST của EXCLUDE, đọc plan, **tránh bẫy cast int4/bigint**, partial index cho sweeper |
| Consistency & concurrency | Check-then-insert | Transaction + lock thủ công | Constraint phân xử; hold hết hạn lười + sweeper `SKIP LOCKED`; xử lý `exclusion_violation` **và** `deadlock_detected`; **có thí nghiệm** đếm double booking |
| Scale & vận hành | Không ước lượng | QPS | QPS + dung lượng index; mở bán: waiting room/queue; partition và hệ quả lên EXCLUDE |
| Trade-off | Một cách | So sánh 2 | So sánh EXCLUDE / `FOR UPDATE` trên lịch / SERIALIZABLE / lock tài nguyên bằng advisory lock / Redis lock |

**Trừ nặng:** check-then-insert không constraint (−3 Consistency); đóng cả hai đầu khoảng khiến liền kề bị chặn (−1 Data model).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: hold có TTL (Redis hoặc cột `expires_at`), kiểm tra chỗ trống nhanh ở cache nhưng sự thật ở DB; vé sự kiện lớn dùng hàng chờ.
