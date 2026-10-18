select id, name, impressions, clicks, round(clicks*100.0/nullif(impressions,0),2) as ctr_pct from f03.campaigns order by clicks*1.0/nullif(impressions,0) desc nulls last, id asc;
