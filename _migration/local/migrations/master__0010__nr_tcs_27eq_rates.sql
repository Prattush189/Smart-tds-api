-- master__0010__nr_tcs_27eq_rates.sql
--
-- Audit Part 1, finding M6: a non-resident collectee (payee tsId 3 = NR
-- non-company, tsId 4 = NR foreign company) could not select ANY 27EQ (TCS)
-- section. The section dropdown is built from GetPaycdByTsid(ayId, tsId), which
-- only returns paycodes that have a tdsrate row for that tsId — and the TCS
-- collection paycodes had rate rows for tsId 1/2/5 (resident) only. So the list
-- was empty for an NR buyer and NR TCS entries were impossible.
--
-- FIX: add NR (tsId 3 and 4) tdsrate rows for the goods-based TCS collections.
-- The 206C collection rate does NOT depend on the collectee's residency, so the
-- NR row carries the SAME base rate as the resident (tsId 1) row — cloned from
-- the live tsId-1 row rather than restated, so it always tracks the actual rate.
-- Surcharge is left at 0 for NR: it is slab-based on the collectee's income and
-- is entered per-entry on the form (the same convention as the 27Q NR sections
-- and master__0006). Cess (4%) is added automatically at generation.
--
-- SCOPE — included: the goods / licence-based collections where a non-resident
-- buyer/licensee is realistic:
--   30 liquor, 31/32 timber, 33 forest produce, 34 scrap, 35 mining,
--   37 toll, 38 parking, 42 coal/lignite/iron, 44 motor vehicle,
--   150 tendu leaves, 151-160 luxury goods.
-- SCOPE — deliberately EXCLUDED:
--   • LRS collections 49, 81, 161, 162 — the Liberalised Remittance Scheme is a
--     FEMA facility for RESIDENT individuals; a non-resident cannot make an LRS
--     remittance, so an NR row for these would be meaningless.
--   • repealed 206C(1D)/(1H) rows 43, 45, 46, 48 — no 2025-Act collection code,
--     already hidden from the AY-26+ dropdown (SectionDisplayFilter).
--
-- Idempotent: NOT EXISTS guard; re-running is a no-op. Forward-only.

INSERT INTO tdsrate (ayid, tsid, paycode, rate, surch, "limit")
SELECT r.ayid, nr.tsid, r.paycode, r.rate, 0.00, r."limit"
FROM tdsrate r
CROSS JOIN (VALUES (3), (4)) AS nr(tsid)
WHERE r.tsid = 1
  AND r.ayid >= 26
  AND r.paycode IN (30, 31, 32, 33, 34, 35, 37, 38, 42, 44,
                    150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160)
  AND NOT EXISTS (
      SELECT 1 FROM tdsrate t
      WHERE t.ayid = r.ayid AND t.tsid = nr.tsid AND t.paycode = r.paycode
  );
