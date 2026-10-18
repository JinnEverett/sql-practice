SELECT id, (ctid::text::point)[0]::int AS page_no, (ctid::text::point)[1]::int - 1 AS slot_no
FROM orders WHERE id <= 5 ORDER BY id;
