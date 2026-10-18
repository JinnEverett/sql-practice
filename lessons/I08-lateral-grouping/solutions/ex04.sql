-- db: shop_s
-- ordered
-- Giải thích: CUBE (a, b) = mọi tổ hợp: (a, b), (a), (b), (). grouping(a, b) trả về số nhị phân: 0 = chi tiết, 1 = cuộn b,
--   2 = cuộn a, 3 = tổng chung. Device thiếu (NULL thật, do dữ liệu thiếu key) phải phân biệt với NULL của dòng tổng → nhãn riêng.
-- Bẫy: coalesce(device, '(tất cả)') gộp nhầm event thiếu device vào nhãn tổng; quên lọc 2 loại event.
SELECT CASE WHEN grouping(properties->>'device') = 1 THEN '(tất cả)'
            ELSE coalesce(properties->>'device', '(không rõ)') END AS device,
       CASE WHEN grouping(event_type) = 1 THEN '(tất cả)' ELSE event_type END AS event_type,
       grouping(properties->>'device', event_type) AS lvl,
       count(*) AS n_events
FROM events
WHERE event_type IN ('add_to_cart', 'checkout')
GROUP BY CUBE (properties->>'device', event_type)
ORDER BY lvl, device, event_type;
