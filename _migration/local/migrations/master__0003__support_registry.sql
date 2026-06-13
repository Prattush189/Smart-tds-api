-- master__0003__support_registry.sql
-- Support/diagnostics registry, written best-effort on every successful login (#2). Lets the
-- vendor identify which client/machine a licence+user is on and recover a forgotten password
-- (pwdenc = AES copy, key = server JWT secret). NOT exposed via any tenant API (that would
-- leak cross-tenant) — read it via direct DB access on the server. In Online mode this is the
-- VPS master DB (centralised for all cloud firms); in Local mode it is that install's own DB.
-- The login writer swallows all errors, so this table being absent never breaks login.
CREATE TABLE IF NOT EXISTS support_registry (
    prodkey      varchar(40)  NOT NULL,
    username     varchar(50)  NOT NULL,
    machineid    varchar(64),
    machinename  varchar(100),
    mode         varchar(16),
    pwdenc       text,
    registeredto varchar(200),
    lastloginutc timestamp,
    CONSTRAINT pk_support_registry PRIMARY KEY (prodkey, username)
);
