-- master__0002__add_user_pwdenc.sql
-- Adds the AES-encrypted recoverable password column used by the admin "view password" /
-- forgotten-password support feature. Login still verifies the one-way PBKDF2 hash in `pwd`;
-- `pwdenc` is the reversible copy (AES-256-CBC, key derived from the server JWT secret).
-- Nullable: rows that predate this column simply have no recoverable copy (hash-only) until
-- their password is next set through the API.
ALTER TABLE users ADD COLUMN IF NOT EXISTS pwdenc text;
