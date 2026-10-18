-- db: lab
-- mode: state
-- Giải thích: Self join trên khóa chuẩn hóa lower(trim(email)); xóa dòng s nếu tồn tại dòng k 'đứng trước' nó theo (created_at, id). So sánh row value (a,b) < (c,d) gói gọn tie-break.
-- Bẫy: Chỉ so created_at → id 3 và 4 cùng created_at, không ai 'đứng trước' ai → giữ cả hai. Cách khác: row_number() OVER (PARTITION BY lower(trim(email)) ORDER BY created_at, id) và xóa rn > 1 (học ở I03).
DELETE FROM f08.subscribers s USING f08.subscribers k
WHERE lower(trim(k.email)) = lower(trim(s.email)) AND (k.created_at, k.id) < (s.created_at, s.id);
