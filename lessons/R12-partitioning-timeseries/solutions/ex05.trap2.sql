-- sai: chỉ DETACH, quên DROP → bảng cũ vẫn tồn tại dưới dạng bảng thường
ALTER TABLE r12.events_p DETACH PARTITION r12.events_p_2026_01;
ALTER TABLE r12.events_p DETACH PARTITION r12.events_p_2026_02;
ALTER TABLE r12.events_p DETACH PARTITION r12.events_p_2026_03;
