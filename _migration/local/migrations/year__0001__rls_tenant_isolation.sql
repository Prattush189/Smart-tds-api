-- Auto-apply year-DB RLS to EXISTING local installs via migrate-local.ps1 (applied
-- to every smarttds<YY>). Mirrors _migration/phase5/04_rls_year.sql — keep in sync.
-- Idempotent. Requires the API that sets app.subcodes to be running.

CREATE OR REPLACE FUNCTION app_owns_year_subcode(p_subcode integer) RETURNS boolean
    LANGUAGE sql STABLE AS $$
        SELECT CASE
            WHEN coalesce(current_setting('app.subcodes', true), '') = '' THEN false
            ELSE p_subcode = ANY (string_to_array(current_setting('app.subcodes', true), ',')::int[])
        END $$;

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

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='smarttds_app') THEN
    GRANT EXECUTE ON FUNCTION app_owns_year_subcode(integer), app_owns_salid(integer) TO smarttds_app;
  END IF;
END $$;
