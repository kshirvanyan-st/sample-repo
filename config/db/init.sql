-- Run once by the Postgres accessory on first boot (docker-entrypoint-initdb.d).
-- The primary database (taxi_am_production) is created from POSTGRES_DB.
CREATE DATABASE taxi_am_production_cache;
CREATE DATABASE taxi_am_production_queue;
CREATE DATABASE taxi_am_production_cable;
