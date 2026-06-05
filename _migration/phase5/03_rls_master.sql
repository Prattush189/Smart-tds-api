-- =====================================================================
-- Row-Level Security (RLS) for the shared MASTER database — defense-in-depth
-- BEHIND the API. Even if an API query forgets a WHERE prodkey=..., the DB
-- only returns/accepts rows belonging to the current tenant.
--
-- TENANT = the GUC  app.prodkey  which the API sets per request from the JWT
-- (DbConnectionFactory -> set_config('app.prodkey', <jwt prodkey>, false)).
-- If it's unset, current_setting(...,true) is NULL -> every policy is false
-- -> DEFAULT DENY (no rows). So a missing tenant can never leak data.
--
-- Applies to the least-privilege role smarttds_app (NOT owner, NOT BYPASSRLS).
-- postgres (table owner) bypasses RLS by default -> migrations/seed/backup as
-- postgres still see everything. Run this AS postgres, AFTER the schema + grants.
--
-- NOT covered (intentionally):
--   * users / licences / sessions  -> auth infra; login queries them before a
--     JWT exists, so RLS there would break login. Guarded by auth logic instead.
--   * reference tables (country/state/district/tdsrate/...) -> shared, read-only.
-- =====================================================================

-- current tenant prodkey (NULL when unset -> default deny)
CREATE OR REPLACE FUNCTION app_current_prodkey() RETURNS varchar
    LANGUAGE sql STABLE AS $$ SELECT current_setting('app.prodkey', true) $$;

-- true if the given assessee subcode belongs to the current tenant
CREATE OR REPLACE FUNCTION app_owns_subcode(p_subcode integer) RETURNS boolean
    LANGUAGE sql STABLE AS $$
        SELECT EXISTS (SELECT 1 FROM assessee a
                       WHERE a.subcode = p_subcode
                         AND a.prodkey = current_setting('app.prodkey', true)) $$;

-- ---------- prodkey-owned tables ----------
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

-- ---------- subcode-owned child tables (ownership via assessee.prodkey) ----------
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

-- ---------- bill children keyed by billid (ownership via billhead.subcode) ----------
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

-- functions must be callable by the app role (skip if the role isn't created yet)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='smarttds_app') THEN
    GRANT EXECUTE ON FUNCTION app_current_prodkey(), app_owns_subcode(integer), app_owns_billid(integer) TO smarttds_app;
  END IF;
END $$;
