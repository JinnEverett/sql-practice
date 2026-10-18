-- db: shop_m
-- mode: manual
-- Demo: OFFSET sâu so với keyset (không ANALYZE). Đo thật xem solutions/ex09.md.
EXPLAIN (COSTS OFF) SELECT id, created_at, total_amount FROM orders ORDER BY created_at DESC, id DESC OFFSET 900000 LIMIT 20;
EXPLAIN (COSTS OFF) SELECT id, created_at, total_amount FROM orders WHERE (created_at, id) < ('2025-02-21 05:57:20.456226+00', 100001) ORDER BY created_at DESC, id DESC LIMIT 20;
