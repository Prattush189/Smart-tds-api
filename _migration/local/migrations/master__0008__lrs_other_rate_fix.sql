-- master__0008__lrs_other_rate_fix.sql
-- LRS remittance for OTHER purposes (paycode 49 -> 2025-Act code 1087): the TY2026-27
-- rate is 20% above the Rs.10 lakh threshold (TDSMAN/TaxGuru charts, verified 2026-07).
-- The ay-26 rows carried a stale 5.00. Guarded on the stale value so a deliberate
-- manual change is never clobbered; idempotent (re-run matches 0 rows).
UPDATE tdsrate SET rate = 20.00
WHERE ayid >= 26 AND paycode = 49 AND rate = 5.00;
