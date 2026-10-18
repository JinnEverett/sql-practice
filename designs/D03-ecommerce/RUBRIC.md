# D03 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Không hỏi giữ chỗ/timeout | Có giữ chỗ, thiếu webhook/hoàn tiền | Chốt giữ chỗ khi nào, timeout, webhook lặp/trễ, snapshot giá, retention 10 năm |
| Data model | float tiền, status text tự do, tồn kho trong `products` | Tách `inventory`, có CHECK >= 0 | + bảng transitions/trigger, `unit_price` snapshot, UNIQUE idempotency & provider_ref, CHECK reserved ≤ on_hand |
| Index & query | Thiếu index user/đơn | Có index, không partial | Partial index đơn pending, index `(user_id, created_at DESC)`, đọc plan |
| Consistency & concurrency | check-then-act ở app | Dùng `SELECT … FOR UPDATE` | `UPDATE … WHERE on_hand - reserved >= n` nguyên tử + khóa theo thứ tự product_id + webhook idempotent; **có thí nghiệm** đo oversell |
| Scale & vận hành | Không bàn flash sale | Có TPS, không bàn hot row | Hot row: số liệu + hướng bucket/queue; partition `orders`; đối soát reserved ↔ pending |
| Trade-off | Một luồng | So sánh 2 cách giữ chỗ | So sánh pessimistic lock / điều kiện trong UPDATE / queue tuần tự / Redis token, nêu độ phức tạp và điểm vỡ |

**Trừ nặng:** thiếu thí nghiệm hoặc kết luận không có số (−2 Consistency). Float cho tiền (−2 Data model).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: giữ chỗ tạm có TTL; flash sale đặt hàng đi qua queue/token trước DB; tồn kho thường là service riêng với bucket.
