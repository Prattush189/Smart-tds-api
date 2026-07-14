-- year__0003__cert_uin_widths.sql
-- 2025-Act certificate/UIN widths. certno and ack15ca were varchar(10):
--   - section 395 lower/no-deduction certificates (reason flag A) are 15 chars;
--   - Form 121 declaration UINs (reason flag B) and Form 15CA acknowledgement
--     numbers are up to 26 chars (FVU spec CHAR 26, deductee fields 31/33).
-- Widen both to 26. Re-run safe (widening an already-26 column is a no-op).
ALTER TABLE tdsentry ALTER COLUMN certno TYPE varchar(26);
ALTER TABLE tdsentry ALTER COLUMN ack15ca TYPE varchar(26);
