# D05 · Booking system

> Đề (cố ý mơ hồ): "Nền tảng đặt phòng/đặt lịch: khách chọn phòng và khung giờ, có vài phút để thanh toán, sau đó chỗ được xác nhận. Không bao giờ được bán một chỗ cho hai người."

## Cách làm bài
1. Hỏi để chốt: tài nguyên là gì (phòng theo đêm? slot theo giờ? ghế cố định? số lượng vé không gán chỗ?), thời gian giữ chỗ, ai/cái gì làm hết hạn, hủy/đổi lịch, múi giờ, mức tải đỉnh.
2. Trọng tâm: **giữ chỗ tạm có hạn**, **hết hạn** (ai dọn?), **chống double booking** ở tầng DB, **múi giờ/ranh giới khoảng**.
3. Nộp `DESIGN.md`, `schema.sql`, `queries.sql`. Bắt buộc có thí nghiệm nhiều client tranh cùng một chỗ, có số đo.

**Pass:** bản thiết kế + review ≥ 22/30.
