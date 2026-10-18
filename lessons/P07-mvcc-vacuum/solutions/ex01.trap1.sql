SELECT lp, t_ctid, false AS has_xmax, false AS hot_updated, false AS heap_only
FROM heap_page_items(get_raw_page('p07.ver', 0)) ORDER BY lp;
