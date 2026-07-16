-- master__0006__nr_surcharge_zero_default.sql
-- Zero the prescribed surcharge on all non-resident TDS rate rows for the
-- 2025-Act years (ayid >= 26, tsid 3 = NR non-corporate, 4 = foreign company).
--
-- WHY: surcharge on NR payments is THRESHOLD-based on the payee's income,
-- never a flat % from the first rupee (verified against the FY 2026-27
-- schedule, Finance Act 2026 Part II):
--   Foreign company:    2% (> Rs 1 cr up to 10 cr), 5% (> Rs 10 cr)
--   NR individual/HUF: 10% (> 50 L), 15% (> 1 cr), 25% (> 2 cr),
--                      37% (> 5 cr, old regime; capped 25% new regime);
--                      capped at 15% on dividends and 111A/112A gains
--   NR firm/co-op:     12% (> Rs 1 cr)
-- The carried-forward rows held stale flat values (2.5% pre-2015 foreign-co
-- rate on legacy paycodes, 2% on some tsid-4 rows) which FrmTdsEntry both
-- auto-applied from rupee one AND enforced as a floor ("Surcharge can not be
-- lower than prescribed"). Default 0 = no surcharge until the deductor enters
-- the slab-appropriate % once the payee crosses a threshold.
-- Cess is unaffected: 4% on (TDS + surcharge) stays hardcoded in the UI.
-- Idempotent.

UPDATE tdsrate SET surch = 0
WHERE ayid >= 26 AND tsid IN (3, 4) AND surch <> 0;
