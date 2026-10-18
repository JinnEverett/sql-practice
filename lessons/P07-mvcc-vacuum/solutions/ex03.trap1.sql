SELECT table_len / 8192 AS pages, tuple_count AS live, dead_tuple_count AS dead, round(dead_tuple_percent)::int AS wasted_pct
FROM pgstattuple('p07.bloat');
