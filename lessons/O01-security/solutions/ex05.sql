-- db: lab
-- mode: check
-- reset
-- Giải thích: GIÁ TRỊ người dùng đưa vào truyền bằng tham số (EXECUTE … USING $1), không ghép vào chuỗi: Postgres coi nó là dữ liệu, không bao giờ
--   là SQL, nên `' OR '1'='1` chỉ là một email lạ. TÊN CỘT/BẢNG không truyền bằng tham số được: kiểm tra trong danh sách cho phép (whitelist) rồi
--   mới chèn bằng format('%I') (quote identifier). Giá trị ngoài whitelist → báo lỗi, không bỏ qua im lặng.
--   Ngoài hàm: ứng dụng dùng prepared statement/parameterized query của driver (PREPARE … EXECUTE, $1) cho mọi giá trị.
-- Bẫy: ghép chuỗi bằng || (hàm _bad trong setup); chỉ thay dấu nháy đơn bằng nháy kép (thiếu trường hợp khác); nhét tên cột vào format('%I') mà không whitelist
--   (người gọi chọn được cột nào cũng được, kể cả cột nhạy cảm); format('%L') cho giá trị cũng đúng nhưng USING gọn hơn và tái dùng được plan.
CREATE FUNCTION o01.find_customer(p_email text, p_order_by text DEFAULT 'id')
RETURNS TABLE (id int, name text)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_order_by NOT IN ('id', 'name', 'email') THEN
    RAISE EXCEPTION 'cột sắp xếp % không được phép', p_order_by USING ERRCODE = 'invalid_parameter_value';
  END IF;
  RETURN QUERY EXECUTE format('SELECT c.id, c.name FROM o01.customers c WHERE c.email = $1 ORDER BY %I', p_order_by) USING p_email;
END $$;
