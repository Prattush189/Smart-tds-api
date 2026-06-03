-- =====================================================================
-- Phase 5 — Licensing & sessions (NEW tables; the API is now the licence
-- authority, replacing the legacy Pump + smartbizindia ServiceUL.svc and the
-- sys.dm_exec seat-counting hack). Apply to masterdbtds.
-- =====================================================================

-- One row per licence key (= the desktop's "Licence Key" / users.prodkey).
CREATE TABLE IF NOT EXISTS licences (
    prodkey       varchar(20) PRIMARY KEY,         -- e.g. PYFA5V_1 (stored UPPER)
    registered_to varchar(125) NOT NULL,           -- shown as "LICENSED TO ..."
    licence_type  varchar(10)  NOT NULL DEFAULT 'Full',   -- Full | Demo
    expiry_date   date         NOT NULL,
    max_seats     int          NOT NULL DEFAULT 3,  -- concurrent session cap
    is_active     boolean      NOT NULL DEFAULT true,
    created_on    timestamp    NOT NULL DEFAULT now(),
    modified_on   timestamp    NOT NULL DEFAULT now()
);

-- Active login sessions — central seat enforcement (stateless API friendly).
CREATE TABLE IF NOT EXISTS sessions (
    jti        uuid        PRIMARY KEY,            -- matches the JWT's jti claim
    prodkey    varchar(20) NOT NULL,
    username   varchar(50) NOT NULL,
    machine    varchar(100),
    issued_on  timestamp   NOT NULL DEFAULT now(),
    expires_on timestamp   NOT NULL,
    last_seen  timestamp   NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_sessions_prodkey ON sessions (prodkey, expires_on);

-- grant to the app role (no-op if role/grants already present)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='smarttds_app') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON licences, sessions TO smarttds_app;
  END IF;
END $$;
