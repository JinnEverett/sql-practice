# D03 · E-commerce

> Đề (cố ý mơ hồ): "Shop online có đợt flash sale mỗi tháng. Khách đặt hàng, thanh toán qua cổng bên thứ ba, sau đó kho đóng gói và giao. Thiết kế phần database cho đơn hàng, tồn kho và thanh toán."

## Cách làm bài
1. Hỏi để chốt: quy mô thường ngày vs flash sale, giữ chỗ tồn kho khi nào (lúc đặt hay lúc thanh toán), timeout thanh toán, hủy/hoàn tiền, nhiều kho hay một, webhook của cổng thanh toán đáng tin đến đâu.
2. Trọng tâm: **chống oversell**, **state machine** của đơn, **idempotency** (đặt đơn, webhook), tách bảng nóng/lạnh.
3. Nộp `DESIGN.md` (ERD, state diagram, sequence cho checkout), `schema.sql`, `queries.sql`.
4. Bắt buộc có **một thí nghiệm concurrency thật** (2+ session hoặc `pgbench`), không chỉ lập luận.

**Pass:** bản thiết kế + review ≥ 22/30.
