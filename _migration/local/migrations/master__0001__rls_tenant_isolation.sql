-- Auto-apply RLS tenant isolation to EXISTING local installs via migrate-local.ps1
-- (runs as postgres on login / API startup). Mirrors _migration/phase5/03_rls_master.sql
-- — keep the two in sync. Idempotent (safe to run alongside provision on new installs).
--
-- NOTE: requires the API that sets app.prodkey to be running, otherwise tenant
-- tables read 0 rows until it is. The release package ships this migration together
-- with the updated API, and the API's startup hook applies it after the new API
-- is live — so order is handled for local installs.

CREATE OR REPLACE FUNCTION app_current_prodkey() RETURNS varchar
    LANGUAGE sql STABLE AS $$ SELECT current_setting('app.prodkey', true) $$;

CREATE OR REPLACE FUNCTION app_owns_subcode(p_subcode integer) RETURNS boolean
    LANGUAGE sql STABLE AS $$
        SELECT EXISTS (SELECT 1 FROM assessee a
                       WHERE a.subcode = p_subcode
                         AND a.prodkey = current_setting('app.prodkey', true)) $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['assessee','consultant','groups'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_%1$s ON %1$s', t);
    EXECUTE format($f$CREATE POLICY tenant_%1$s ON %1$s
        USING (prodkey = app_current_prodkey())
        WITH CHECK (prodkey = app_current_prodkey())$f$, t);
  END LOOP;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['bankdetails','assesseerep','assesseeresstatus',
                           'returndates','feepaidmarking','billhead',
                           'billmast','billreceipt'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_%1$s ON %1$s', t);
    EXECUTE format($f$CREATE POLICY tenant_%1$s ON %1$s
        USING (app_owns_subcode(subcode))
        WITH CHECK (app_owns_subcode(subcode))$f$, t);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION app_owns_billid(p_billid integer) RETURNS boolean
    LANGUAGE sql STABLE AS $$
        SELECT EXISTS (SELECT 1 FROM billhead b WHERE b.id = p_billid
                       AND app_owns_subcode(b.subcode)) $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['billdetails','billreceipts'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_%1$s ON %1$s', t);
    EXECUTE format($f$CREATE POLICY tenant_%1$s ON %1$s
        USING (app_owns_billid(billid))
        WITH CHECK (app_owns_billid(billid))$f$, t);
  END LOOP;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='smarttds_app') THEN
    GRANT EXECUTE ON FUNCTION app_current_prodkey(), app_owns_subcode(integer), app_owns_billid(integer) TO smarttds_app;
  END IF;
END $$;
