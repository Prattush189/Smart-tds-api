-- =====================================================================
-- Row-Level Security for the per-YEAR databases (smarttds<YY>) — defense-in-depth.
-- Year tables have no prodkey column (and assessee lives in the master DB, no
-- cross-DB join), so the tenant key here is the GUC  app.subcodes  — the CSV list
-- of the firm's assessee subcodes, which the API sets per request (it reads them
-- from master, where assessee already has prodkey RLS).
--
-- Unset/empty app.subcodes -> every policy false -> DEFAULT DENY (no rows).
-- Enforced on smarttds_app; postgres (owner) bypasses. Run AS postgres, per year DB.
-- =====================================================================

-- true if subcode is in the current tenant's CSV (empty/unset -> false = deny)
CREATE OR REPLACE FUNCTION app_owns_year_subcode(p_subcode integer) RETURNS boolean
    LANGUAGE sql STABLE AS $$
        SELECT CASE
            WHEN coalesce(current_setting('app.subcodes', true), '') = '' THEN false
            ELSE p_subcode = ANY (string_to_array(current_setting('app.subcodes', true), ',')::int[])
        END $$;

-- ---------- subcode-keyed tables ----------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['payee','tdsentry','addchallan','salary','tdsdeduction',
                           'tdscompincome','filingstatus','ddodet','f15hn','f15hnpayee'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_%1$s ON %1$s', t);
    EXECUTE format($f$CREATE POLICY tenant_%1$s ON %1$s
        USING (app_owns_year_subcode(subcode))
        WITH CHECK (app_owns_year_subcode(subcode))$f$, t);
  END LOOP;
END $$;

-- ---------- salary child tables (salid -> salary.subcode) ----------
CREATE OR REPLACE FUNCTION app_owns_salid(p_salid integer) RETURNS boolean
    LANGUAGE sql STABLE AS $$
        SELECT EXISTS (SELECT 1 FROM salary s WHERE s.id = p_salid
                       AND app_owns_year_subcode(s.subcode)) $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['salarynaturedetails','salaryexemptallowances','salaryperquisitedetails'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_%1$s ON %1$s', t);
    EXECUTE format($f$CREATE POLICY tenant_%1$s ON %1$s
        USING (app_owns_salid(salid))
        WITH CHECK (app_owns_salid(salid))$f$, t);
  END LOOP;
END $$;

-- applicationparams (year-level config, e.g. 'ver') has no subcode -> NOT tenant data, left open.

-- grants (skip if the app role isn't created yet)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='smarttds_app') THEN
    GRANT EXECUTE ON FUNCTION app_owns_year_subcode(integer), app_owns_salid(integer) TO smarttds_app;
  END IF;
END $$;
