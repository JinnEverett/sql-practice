# D04 · Banking ledger

> Đề (cố ý mơ hồ): "Một ví điện tử cần sổ cái cho tiền của khách: nạp, chuyển cho nhau, rút. Kế toán yêu cầu số liệu luôn khớp và có thể truy vết từng đồng. Thiết kế phần database."

## Cách làm bài
1. Hỏi để chốt: đa tiền tệ?, thấu chi?, phí, hoàn tiền/đảo giao dịch, đối soát với ngân hàng đối tác, số dư hiện tại phải nhanh đến đâu, yêu cầu kiểm toán/retention.
2. Trọng tâm: **double-entry**, **số dư** (lưu hay tính?), **chuyển tiền idempotent**, **append-only + bù trừ**, **đối soát**.
3. Nộp `DESIGN.md`, `schema.sql`, `queries.sql`. Bắt buộc có thí nghiệm 2+ session/`pgbench` chứng minh không mất/sinh tiền và không deadlock.

**Pass:** bản thiết kế + review ≥ 22/30.
