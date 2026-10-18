-- db: lab
-- mode: check
-- reset
-- Giải thích: adjacency list không tự chặn chu trình (A là cha của B, B là cha của A) và FK không giúp được. Dùng trigger BEFORE INSERT OR UPDATE OF parent_id:
--   đi lên từ cha mới bằng recursive CTE; nếu gặp lại chính nút đang sửa (hoặc cha mới = chính nó) thì đây là chu trình → RAISE check_violation (23514).
--   Chi phí O(độ sâu) mỗi lần ghi, chấp nhận được vì cây danh mục ít thay đổi.
-- Bẫy: chỉ kiểm cha mới ≠ chính nó (bỏ sót chu trình dài); kiểm sau khi ghi (AFTER) khiến dữ liệu xấu đã vào bảng trong transaction; quên điều kiện WHEN/TG_OP cho INSERT (NEW.id có thể chưa có hậu duệ nhưng cha mới = chính nó vẫn phải chặn).
CREATE FUNCTION r06.no_cycle() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.parent_id IS NULL THEN RETURN NEW; END IF;
  IF NEW.parent_id = NEW.id OR EXISTS (
       WITH RECURSIVE up AS (
         SELECT id, parent_id FROM r06.cat WHERE id = NEW.parent_id
         UNION ALL
         SELECT c.id, c.parent_id FROM r06.cat c JOIN up ON c.id = up.parent_id)
       SELECT 1 FROM up WHERE id = NEW.id) THEN
    RAISE EXCEPTION 'chu trình: % không thể là con của % hoặc hậu duệ của nó', NEW.id, NEW.parent_id USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER cat_no_cycle BEFORE INSERT OR UPDATE OF parent_id ON r06.cat
  FOR EACH ROW EXECUTE FUNCTION r06.no_cycle();
