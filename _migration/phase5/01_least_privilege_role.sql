-- =====================================================================
-- Phase 5 — least-privilege application role for SmartTds
-- Replaces the legacy `sa` / `pass.123` superuser usage (Phase 0 security debt).
-- The API connects as `smarttds_app`: CRUD only, NO DDL, NO DROP/TRUNCATE,
-- NO superuser. Run the role creation ONCE (cluster level), then the per-DB
-- grants for masterdbtds and EACH year DB (smarttds26, ...).
-- =====================================================================

-- 1) cluster-level role (run once, connected to any DB as a superuser)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smarttds_app') THEN
    CREATE ROLE smarttds_app LOGIN PASSWORD 'CHANGE_ME'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
  END IF;
END $$;

-- 2) per-database grants. Re-run this block for masterdbtds AND each year DB.
--    (psql:  \c masterdbtds   then run;   \c smarttds26   then run;  ...)
GRANT CONNECT ON DATABASE :"dbname" TO smarttds_app;  -- pass -v dbname=masterdbtds
GRANT USAGE ON SCHEMA public TO smarttds_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO smarttds_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO smarttds_app;
-- future tables/sequences auto-granted (so newly provisioned year DBs just work):
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO smarttds_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO smarttds_app;

-- Note: NOT granted -> CREATE/ALTER/DROP/TRUNCATE on tables, schema CREATE,
-- and no access to other roles' objects. Schema migrations run as a separate
-- owner/admin role, never as smarttds_app.
