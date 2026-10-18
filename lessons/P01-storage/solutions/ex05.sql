-- db: lab
-- mode: check
-- reset
-- Giải thích: octet_length(text) lấy độ dài từ header của giá trị TOAST mà không đọc chunk nên seq scan chỉ đọc 14 page heap.
--   length(text) đếm ký tự, bắt buộc detoast cả 60 KB × 300 dòng = hơn 2 000 page.
-- Bẫy: length(body); lower(body) ~ …; body LIKE …
SELECT count(*) AS n FROM p01.docs WHERE octet_length(body) > 50000;
