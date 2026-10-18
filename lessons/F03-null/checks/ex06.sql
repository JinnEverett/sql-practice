-- db: lab
-- ordered
SELECT id, name, impressions, clicks,
       round(clicks * 100.0 / nullif(impressions, 0), 2) AS ctr_pct
FROM f03.campaigns ORDER BY ctr_pct DESC NULLS LAST, id;
