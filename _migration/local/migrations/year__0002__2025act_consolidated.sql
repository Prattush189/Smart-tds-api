-- year__0002__2025act_consolidated.sql
-- Year-DB deltas: salaryparty table, payee India-country fix, 194P/PE flags, LC3 paycode relink.
-- Consolidation of: 0002, 0003, 0004, 0005 - all idempotent; re-runs are no-ops on DBs that already ran the originals.

-- ============================================================
-- >> from year__0002__salary_party_details.sql
-- ============================================================
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

-- ============================================================
-- >> from year__0003__payee_country_india_fix.sql
-- ============================================================
-- year__0003__payee_country_india_fix.sql
-- Payee.country uses the SEQUENTIAL NSDL/Annexure-10 country scheme (India = 113),
-- but FrmPayee's dropdown was wired to the PAYER dial-style list and defaulted every
-- new payee to 91. Under the serial scheme 91 = GERMANY, so those defaulted rows
-- mislabel Indian payees. Recode them to 113.
--
-- Safe because 91 could only have arrived via that wrong default (a genuine German
-- payee could not be selected: the dial list the form showed has no Germany=91 row
-- either - Germany is 49 there). Idempotent (second run matches 0 rows).
UPDATE payee SET country = 113 WHERE country = 91;

-- ============================================================
-- >> from year__0004__payee_194p_pe_flags.sql
-- ============================================================
-- year__0004__payee_194p_pe_flags.sql
-- Two per-payee flags needed by the 2025-Act generators:
--   sr194p    - employee is a "specified senior citizen" u/s 194P: the 24Q DD section
--               code becomes 1032 (393(1) [Table: Sl. No. 8(iii)]) instead of the
--               employer-category 1001/1002/1003 default.
--   peinindia - non-resident collectee has a Permanent Establishment in India: drives
--               27EQ DD field 13 (was hardcoded 'N' for every NR).
-- Idempotent.
ALTER TABLE payee ADD COLUMN IF NOT EXISTS sr194p    boolean NOT NULL DEFAULT false;
ALTER TABLE payee ADD COLUMN IF NOT EXISTS peinindia boolean NOT NULL DEFAULT false;

-- ============================================================
-- >> from year__0005__lc3_paycode_relink.sql
-- ============================================================
-- year__0005__lc3_paycode_relink.sql
-- master__0010 moved 27Q section 194LC3 from the shared paycode 99 (collision with
-- 26Q 194E) to its own paycode 139. Relink any year-DB TDS entries saved under the
-- old paycode. 26Q 194E entries (also section=99 but formtype 26Q) are untouched.
-- Idempotent.
UPDATE tdsentry SET section = 139 WHERE section = 99 AND formtype = '27Q';

