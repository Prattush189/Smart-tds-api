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
