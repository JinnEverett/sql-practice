CREATE INDEX ON p10.t_m (gen);
-- query
WITH f AS (SELECT id, ts FROM p10.t_m WHERE gen < 5000)
SELECT id, ts FROM f ORDER BY ts DESC LIMIT 20;
