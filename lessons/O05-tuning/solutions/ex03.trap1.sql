-- Lời giải SAI: thấy đĩa tạm chỉ ~46 MB nên đặt 64MB; bộ nhớ cần để sort trong RAM lớn hơn thế (≈ 73 MB) nên vẫn tràn ra đĩa.
SET LOCAL work_mem = '64MB';
