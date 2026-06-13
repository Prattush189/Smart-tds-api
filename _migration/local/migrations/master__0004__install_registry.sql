-- master__0004__install_registry.sql
-- Central record of every LOCAL Database.exe install, so the vendor can look up a client's
-- PostgreSQL credentials for remote support. Populated best-effort by install-local.ps1 via
-- POST /api/support/install (machine-id keyed; only local installs run Database.exe). Lives
-- on the VPS master DB (the central registry). Passwords are AES-encrypted at rest
-- (superpwdenc / approlepwdenc, key = server JWT secret) — never plaintext. Read it via
-- direct DB access on the VPS; there is NO tenant API that returns it.
CREATE TABLE IF NOT EXISTS install_registry (
    machineid     varchar(64)  NOT NULL,
    machinename   varchar(100),
    dbport        integer,
    superuser     varchar(64),
    superpwdenc   text,
    approleuser   varchar(64),
    approlepwdenc text,
    appversion    varchar(40),
    clientip      varchar(64),
    installedutc  timestamp,
    lastseenutc   timestamp,
    CONSTRAINT pk_install_registry PRIMARY KEY (machineid)
);
