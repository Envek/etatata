CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS vehicles;

CREATE TABLE vehicles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  position  geography,
  available boolean DEFAULT false,
  CONSTRAINT vehicles_pkey PRIMARY KEY (id)
);

CREATE INDEX vehicles_position_idx ON vehicles USING GIST (position);

INSERT INTO vehicles (position, available)
  SELECT
    ST_SetSRID(ST_MakePoint(37.61778 + (n*random() - 5000.00)/50000.00, 55.75583 + (n*random() - 5000.00)/50000.00),4326) AS position,
    n % 2 = 0 AS available
  FROM generate_series(1,10000) As n;
