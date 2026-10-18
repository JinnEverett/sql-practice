# P10b · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.*`.

## ex01 · Nạp dữ liệu: từng dòng, lô, COPY
<details><summary>H1</summary>Mỗi câu lệnh autocommit là một transaction: một lần fsync WAL và một xid.</details>
<details><summary>H2</summary>Gộp nhiều dòng vào một câu hoặc một transaction; COPY bỏ thêm chi phí phân tích câu lệnh.</details>
<details><summary>H3</summary>Dự đoán: từng dòng chậm hơn INSERT … SELECT/COPY khoảng 150×.</details>

## ex02 · Chi phí index khi ghi
<details><summary>H1</summary>Mỗi dòng mới thêm một entry vào <b>mọi</b> index.</details>
<details><summary>H2</summary>Thời gian và WAL tăng gần tuyến tính theo số index; dung lượng index cũng vậy.</details>
<details><summary>H3</summary>Nạp hàng loạt: bỏ index phụ rồi tạo lại sau thường rẻ hơn (so sánh với thời gian CREATE INDEX ở ex04).</details>

## ex03 · Nạp 5 000 dòng mà không tiêu 5 000 xid
<details><summary>H1</summary>Một transaction = một xid, bất kể bao nhiêu dòng.</details>
<details><summary>H2</summary>Một câu lệnh đã là một transaction. Câu lệnh nào chèn nhiều dòng một lúc?</details>
<details><summary>H3</summary><code>INSERT INTO p10b.dst SELECT id, v, pad FROM p10b.src;</code></details>

## ex04 · Xây index mà không chặn ghi
<details><summary>H1</summary>Có một dạng CREATE INDEX giữ khóa nhẹ hơn.</details>
<details><summary>H2</summary><code>CREATE INDEX CONCURRENTLY</code>; không chạy được trong <code>BEGIN … COMMIT</code>.</details>
<details><summary>H3</summary><code>CREATE INDEX CONCURRENTLY t4_slow_idx ON p10b.t4 (p10b.slow_id(id));</code></details>

## ex05 · ALTER TABLE: rewrite hay không
<details><summary>H1</summary>Thay đổi chỉ ở catalog thì tức thì; thay đổi phải ghi lại từng dòng thì tỉ lệ với N.</details>
<details><summary>H2</summary>Default là hằng (Postgres 11+) không rewrite; default volatile và đổi kiểu thì rewrite. Ràng buộc mới phải quét bảng.</details>
<details><summary>H3</summary>Thời gian rewrite = thời gian giữ ACCESS EXCLUSIVE. Đo trong <code>BEGIN … ROLLBACK</code>.</details>

## ex06 · Bloat, VACUUM, ANALYZE, dung lượng theo N
<details><summary>H1</summary>UPDATE toàn bảng nhân đôi file cho tới khi VACUUM; chia lô và VACUUM chen vào thì không.</details>
<details><summary>H2</summary>ANALYZE đọc mẫu cố định; VACUUM đọc theo kích thước bảng.</details>
<details><summary>H3</summary>Peak dung lượng của cách chia lô thấp hơn cách một câu.</details>

## ex07 · Thêm CHECK lên bảng lớn
<details><summary>H1</summary>Tách việc "đặt luật cho dòng mới" khỏi "kiểm dữ liệu cũ".</details>
<details><summary>H2</summary><code>ADD CONSTRAINT … NOT VALID</code> rồi <code>VALIDATE CONSTRAINT</code>.</details>
<details><summary>H3</summary>VALIDATE chỉ giữ <code>ShareUpdateExclusiveLock</code>: ghi vẫn chạy.</details>

## ex08 · Backfill cột mới theo lô
<details><summary>H1</summary>Một UPDATE lớn là một transaction lớn.</details>
<details><summary>H2</summary>DO block cho phép <code>COMMIT</code> giữa các lô khi chạy ngoài transaction.</details>
<details><summary>H3</summary>Lô 10 000 dòng theo khoảng <code>id</code>; không dùng OFFSET.</details>
