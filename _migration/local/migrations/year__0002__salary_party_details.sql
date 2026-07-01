-- year__0002__salary_party_details.sql
-- Landlord (HRA / rent > 1 lakh) and Lender (housing-loan interest) PAN + name captured
-- per employee for the 24Q Annexure-II SD record (fields 39-48 landlord, 49-58 lender).
-- Per-AY salary data, so it lives in the year DBs (like salary). Keyed by the employee
-- (subcode + ayid + pcode). partytype = 'Landlord' | 'Lender'. Up to 4 of each per employee.
-- Tenant-isolated by subcode (RLS keys on app.subcodes via app_owns_year_subcode, same as
-- the salary table). Idempotent.
CREATE TABLE IF NOT EXISTS salaryparty (
    id        serial PRIMARY KEY,
    subcode   integer     NOT NULL,
    ayid      integer     NOT NULL,
    pcode     integer     NOT NULL,   -- employee (payee id)
    partytype varchar(10) NOT NULL,   -- 'Landlord' | 'Lender'
    pan       varchar(10),
    name      varchar(200),
    createdon timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_salaryparty_emp ON salaryparty (subcode, ayid, pcode);

ALTER TABLE salaryparty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_salaryparty ON salaryparty;
CREATE POLICY tenant_salaryparty ON salaryparty
    USING (app_owns_year_subcode(subcode))
    WITH CHECK (app_owns_year_subcode(subcode));
