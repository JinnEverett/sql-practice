-- show-output
INSERT INTO f08.newsletter (email) VALUES ('an@x.vn'),('dung@x.vn'),('binh@x.vn'),('emi@x.vn'),('dung@x.vn') ON CONFLICT DO NOTHING RETURNING email;
