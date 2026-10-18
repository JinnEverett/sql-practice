-- db: lab
-- mode: state
-- show-output
-- Giải thích: ON CONFLICT DO NOTHING bỏ qua cả email đã có lẫn email trùng trong chính danh sách. RETURNING chỉ trả về dòng thật sự được chèn.
-- Bẫy: ON CONFLICT DO UPDATE với danh sách tự trùng sẽ lỗi 'cannot affect row a second time'; DO NOTHING thì không.
INSERT INTO f08.newsletter (email) VALUES ('an@x.vn'),('dung@x.vn'),('binh@x.vn'),('emi@x.vn'),('dung@x.vn') ON CONFLICT DO NOTHING RETURNING email;
