ALTER TABLE p01.counters SET (fillfactor = 50);
CLUSTER p01.counters USING counters_label_idx;
