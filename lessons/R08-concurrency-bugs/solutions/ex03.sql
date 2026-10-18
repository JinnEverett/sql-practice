-- db: lab
-- mode: check
-- Giải thích: optimistic locking = KHÔNG giữ khóa khi người dùng đang sửa; mỗi dòng có cột version. Client đọc dòng (kèm version), sửa, rồi ghi với điều kiện
--   `WHERE id = ? AND version = <version đã đọc>` và tăng version. Có ai sửa xen vào thì version đã đổi, UPDATE khớp 0 dòng → trả false để client đọc lại và quyết định.
--   Kiểm tra và ghi nằm trong CÙNG một câu UPDATE nên không có khoảng hở. Phù hợp khi xung đột hiếm và "đọc → người dùng sửa → ghi" kéo dài (form chỉnh sửa),
--   khi xung đột thường xuyên thì khóa bi quan (SELECT … FOR UPDATE) hoặc UPDATE nguyên tử hợp hơn.
-- Bẫy: kiểm tra version bằng SELECT riêng rồi UPDATE (check-then-act); quên tăng version khi ghi; quên điều kiện version trong WHERE (ghi đè mù, như lost update).
CREATE FUNCTION r08.update_price(p_id int, p_expected_version int, p_new_price numeric) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r08.products SET price = p_new_price, version = version + 1 WHERE id = p_id AND version = p_expected_version;
  RETURN FOUND;
END $$;
