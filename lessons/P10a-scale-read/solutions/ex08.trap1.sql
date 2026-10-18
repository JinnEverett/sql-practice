CREATE INDEX ON p10.t_m (gen, ts DESC);
-- query
SELECT id, ts FROM p10.t_m WHERE gen < 5000 ORDER BY ts DESC LIMIT 20;
