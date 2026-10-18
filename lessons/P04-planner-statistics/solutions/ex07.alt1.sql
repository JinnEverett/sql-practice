CREATE STATISTICS fact_all (ndistinct, dependencies) ON a, b FROM p04.fact;
ANALYZE p04.fact;
