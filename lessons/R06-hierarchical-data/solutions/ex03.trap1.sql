-- sai: path chỉ là id của chính nút (không có tổ tiên)
UPDATE r06.cat SET path = id::text::ltree;
