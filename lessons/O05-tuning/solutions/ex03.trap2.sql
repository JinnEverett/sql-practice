-- Lời giải SAI: đặt 1GB "cho chắc". Hết tràn đĩa nhưng vượt trần 256MB (mỗi node × mỗi kết nối đều có thể xin chừng đó).
SET LOCAL work_mem = '1GB';
