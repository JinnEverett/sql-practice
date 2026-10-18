-- db: lab
-- mode: manual
-- Demo: thiết kế tham chiếu cho phòng khám (schema r01_clinic). Chạy được nhiều lần, không đụng bảng của bài khác.
DROP SCHEMA IF EXISTS r01_clinic CASCADE;
CREATE SCHEMA r01_clinic;
SET search_path = r01_clinic, public;

CREATE TABLE patients (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name  text NOT NULL,
  birth_date date,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE patient_phones (            -- đa trị → bảng riêng (1NF)
  patient_id bigint NOT NULL REFERENCES patients ON DELETE CASCADE,
  phone      text   NOT NULL,
  is_primary boolean NOT NULL DEFAULT false,
  PRIMARY KEY (patient_id, phone)
);
CREATE UNIQUE INDEX patient_phones_primary_uq ON patient_phones (patient_id) WHERE is_primary;

CREATE TABLE specialties (id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE doctors (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, full_name text NOT NULL, active boolean NOT NULL DEFAULT true);
CREATE TABLE doctor_specialties (        -- nhiều-nhiều
  doctor_id    int      NOT NULL REFERENCES doctors ON DELETE CASCADE,
  specialty_id smallint NOT NULL REFERENCES specialties,
  PRIMARY KEY (doctor_id, specialty_id)
);

CREATE TABLE services (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE service_prices (            -- giá đổi theo thời gian → lịch sử, không ghi đè
  service_id int NOT NULL REFERENCES services,
  valid_from date NOT NULL,
  price      numeric(12,2) NOT NULL CHECK (price >= 0),
  PRIMARY KEY (service_id, valid_from)
);

CREATE TABLE appointments (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id bigint NOT NULL REFERENCES patients,
  doctor_id  int    NOT NULL REFERENCES doctors,
  starts_at  timestamptz NOT NULL,
  status     text NOT NULL DEFAULT 'booked' CHECK (status IN ('booked', 'done', 'cancelled', 'no_show'))
);
CREATE INDEX appointments_patient_idx ON appointments (patient_id, starts_at);   -- FK không tự có index
CREATE INDEX appointments_doctor_idx  ON appointments (doctor_id, starts_at);
CREATE TABLE appointment_services (      -- chụp giá lúc khám (snapshot), không join lại bảng giá hiện tại
  appointment_id bigint NOT NULL REFERENCES appointments ON DELETE CASCADE,
  service_id     int    NOT NULL REFERENCES services,
  charged_price  numeric(12,2) NOT NULL CHECK (charged_price >= 0),
  PRIMARY KEY (appointment_id, service_id)
);
CREATE INDEX appointment_services_service_idx ON appointment_services (service_id);
RESET search_path;
SELECT count(*) AS n_tables FROM pg_tables WHERE schemaname = 'r01_clinic';
