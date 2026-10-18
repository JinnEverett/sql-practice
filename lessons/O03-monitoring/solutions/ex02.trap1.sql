SELECT left(query, 80) AS query, calls, shared_blks_hit + shared_blks_read AS blks_total,
       round((shared_blks_hit + shared_blks_read)::numeric / nullif(calls, 0), 1) AS blks_per_call
FROM pg_stat_statements WHERE query NOT ILIKE '%pg_stat_statements%' ORDER BY calls DESC LIMIT 3;
