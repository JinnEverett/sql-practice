BEGIN;
:ans
;
-- Đọc hết feed theo từng trang 13 dòng, giống một client cuộn vô hạn; sau mỗi trang có 2 bài MỚI được đăng (created_at mới hơn tất cả).
CREATE TEMP TABLE seen (id bigint, page int) ON COMMIT DROP;
DO $chk$
DECLARE c_ts timestamptz; c_id bigint; n int; pg int := 0;
BEGIN
  LOOP
    pg := pg + 1;
    INSERT INTO seen SELECT p.id, pg FROM r02.feed_page(c_ts, c_id, 13) p;
    GET DIAGNOSTICS n = ROW_COUNT;
    EXIT WHEN n = 0 OR pg > 40;
    SELECT f.created_at, f.id INTO c_ts, c_id FROM r02.feed f WHERE f.id = (SELECT min(s.id) FROM seen s WHERE s.page = pg);
    INSERT INTO r02.feed (created_at, title) VALUES ('2026-02-01 00:00+00', 'mới ' || pg), ('2026-02-01 00:00+00', 'mới ' || pg || 'b');
  END LOOP;
END $chk$;
SELECT pg_temp.ck((SELECT count(*) FROM seen) = 200, 'đọc đủ 200 bài gốc qua các trang, không mất bài (đọc được ' || (SELECT count(*) FROM seen) || ')');
SELECT pg_temp.ck((SELECT count(DISTINCT id) FROM seen) = (SELECT count(*) FROM seen), 'không bài nào xuất hiện hai lần');
SELECT pg_temp.ck((SELECT count(*) FROM seen WHERE id > 200) = 0, 'bài mới đăng không chen vào các trang đang đọc');
SELECT pg_temp.ck((SELECT array_agg(id ORDER BY created_at DESC, id DESC) FROM r02.feed_page(NULL, NULL, 3)) = (SELECT array_agg(id ORDER BY created_at DESC, id DESC) FROM (SELECT id, created_at FROM r02.feed ORDER BY created_at DESC, id DESC LIMIT 3) t), 'cursor NULL trả về trang đầu');
ROLLBACK;
