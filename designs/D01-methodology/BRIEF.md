# D01 · Phương pháp: hệ thống vote bài đăng

> Đề (cố ý mơ hồ): "Công ty muốn thêm tính năng upvote/downvote cho diễn đàn nội bộ. Bài hot phải lên đầu trang chủ. Hãy thiết kế phần database."

## Cách làm bài
1. Đừng vẽ bảng ngay. Hỏi lại tối thiểu 5 câu để chốt phạm vi (ai vote, vote mấy lần, có đổi ý không, "hot" nghĩa là gì, bao nhiêu người dùng).
2. Đi đủ **7 bước** của khung: Requirements → Access patterns → Ước lượng → Data model → Index & query → Kiến trúc → Bottleneck & trade-off. Mỗi bước trình bày xong mới sang bước sau; interviewer sẽ phản biện.
3. Nộp `DESIGN.md` (có `erDiagram`, `flowchart`/`sequenceDiagram`), `schema.sql`, `queries.sql`.

**Pass:** áp dụng đủ checklist 7 bước, mỗi bước có ít nhất một con số hoặc một quyết định có lý do.
