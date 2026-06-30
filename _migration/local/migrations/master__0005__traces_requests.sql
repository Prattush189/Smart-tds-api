-- master__0005__traces_requests.sql
-- TRACES download-request register: one row per Form 16 / 16A / 27D / Conso /
-- Justification request raised on TRACES, tracking the request number and (after the
-- file is downloaded) the saved file path. Lives in MASTER (not a year DB) because the
-- TRACES automation form lets the user pick ANY financial year independent of the open
-- assessment year, so a payer's requests must be viewable together in one grid.
-- Tenant-isolated by subcode, same pattern as bankdetails/assesseerep in master__0001.
-- Column names are all-lowercase no-underscore to match the existing schema convention
-- (clean case-insensitive mapping to the camelCase TracesRequest entity).
-- Idempotent: safe to run on new and existing installs (migrate-local.ps1).
CREATE TABLE IF NOT EXISTS tracesrequest (
    id           serial PRIMARY KEY,
    subcode      integer      NOT NULL,
    tan          varchar(10),
    requesttype  varchar(12)  NOT NULL,   -- Form16 / Form16a / Form27d / Conso / Justi
    frmno        varchar(6),              -- 24Q / 26Q / 27Q / 27EQ
    finyr        varchar(7)   NOT NULL,   -- e.g. 2025-26
    quarter      varchar(4),              -- Q1..Q4
    requestno    varchar(40),             -- number returned by TRACES
    requestdate  date,
    status       varchar(16)  NOT NULL DEFAULT 'Requested',  -- Requested/Available/Downloaded/Failed
    filepath     text,                    -- where the downloaded file was saved
    downloadedon timestamptz,
    remarks      text,
    createdon    timestamptz  NOT NULL DEFAULT now(),
    updatedon    timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_tracesrequest_subcode ON tracesrequest (subcode);

-- Row-level security: a row is visible/writable only when its subcode belongs to the
-- current tenant (app.prodkey, set per-connection by DbConnectionFactory). app_owns_subcode
-- is created + granted to smarttds_app in master__0001. Grants on this new table are
-- (re)applied by migrate-local.ps1's least-privilege step after the migration runs.
ALTER TABLE tracesrequest ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_tracesrequest ON tracesrequest;
CREATE POLICY tenant_tracesrequest ON tracesrequest
    USING (app_owns_subcode(subcode))
    WITH CHECK (app_owns_subcode(subcode));
