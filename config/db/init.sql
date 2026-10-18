-- Run once by the Postgres accessory on first boot (docker-entrypoint-initdb.d).
-- The primary database (spark_production) is created from POSTGRES_DB.
CREATE DATABASE spark_production_cache;
CREATE DATABASE spark_production_queue;
CREATE DATABASE spark_production_cable;
