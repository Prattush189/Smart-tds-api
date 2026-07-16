-- master__0007__newact_rate_threshold_audit.sql
-- TDS-entry audit corrections for the 2025-Act years, fact-checked against
-- the TY 2026-27 schedule (Income-tax Act 2025 / Finance Act 2026):
--
-- RATES (tdsrate, ayid >= 26):
--   paycode 13  "NRI any other income", foreign co: 40% -> 35% (FA-2024 cut;
--               the new-act 27Q rows already used 35, this legacy row missed).
--   paycode 12  "NRI LTC gain": 20% -> 12.5% (post-Jul-2024 LTCG rate; the
--               196B/196C new-act rows were already 12.5%).
--   paycode 23  194G commission on lottery tickets: 10% -> 2% (cut Oct-2024;
--               10% was never the rate - old was 5%).
--
-- THRESHOLDS (tdsentriessection."limit" - NOT year-scoped; legacy years are
-- accepted collateral per user decision - nobody files old years from here):
--   194BB 10,000 (per single transaction - entry-wise logic is in FrmTdsEntry)
--   194K 10,000 | 194A bank 50,000 / senior 1,00,000 | 194J(ba) 50,000/FY
--   194IA 50L | 194Q 50L | 194N 1cr | 194NC 3cr | 194N non-filers 20L
--   194I rows stamped 50,000 (monthly - the month scoping lives in FrmTdsEntry)
--   TCS: motor vehicle 10L/txn, luxury goods 10L/txn, LRS 10L
--   (194O 5L Ind/HUF-only is payee-conditional -> handled in code, not here.)
--
-- KNOWN LIMITATION (not addressed): 194Q/194N/LRS legally tax only the amount
-- EXCEEDING the threshold; the entry form's catch-up model taxes the whole
-- aggregate once crossed. Needs a per-section excess-only flag - future work.
-- Idempotent.

-- rates
UPDATE tdsrate SET rate = 35    WHERE ayid >= 26 AND paycode = 13 AND tsid = 4 AND rate = 40;
UPDATE tdsrate SET rate = 12.50 WHERE ayid >= 26 AND paycode = 12 AND tsid IN (3,4) AND rate = 20;
UPDATE tdsrate SET rate = 2.00  WHERE ayid >= 26 AND paycode = 23 AND rate = 10;

-- TDS thresholds (26Q)
UPDATE tdsentriessection SET "limit" = 10000    WHERE formname = '26Q' AND paycode = 77  AND "limit" <> 10000;    -- 194BB
UPDATE tdsentriessection SET "limit" = 10000    WHERE formname = '26Q' AND paycode = 83  AND "limit" <> 10000;    -- 194K
UPDATE tdsentriessection SET "limit" = 100000   WHERE formname = '26Q' AND paycode = 120 AND "limit" <> 100000;   -- 194A senior (bank/co-op/PO)
UPDATE tdsentriessection SET "limit" = 50000    WHERE formname = '26Q' AND paycode = 121 AND "limit" <> 50000;    -- 194A non-senior (bank/co-op/PO)
UPDATE tdsentriessection SET "limit" = 50000    WHERE formname = '26Q' AND paycode = 123 AND "limit" <> 50000;    -- 194J(ba) royalty
UPDATE tdsentriessection SET "limit" = 5000000  WHERE formname = '26Q' AND paycode = 60  AND "limit" <> 5000000;  -- 194IA property
UPDATE tdsentriessection SET "limit" = 5000000  WHERE formname = '26Q' AND paycode = 70  AND "limit" <> 5000000;  -- 194Q goods
UPDATE tdsentriessection SET "limit" = 10000000 WHERE formname = '26Q' AND paycode = 63  AND "limit" <> 10000000; -- 194N cash withdrawal
UPDATE tdsentriessection SET "limit" = 30000000 WHERE formname = '26Q' AND paycode = 93  AND "limit" <> 30000000; -- 194NC co-op
UPDATE tdsentriessection SET "limit" = 2000000  WHERE formname = '26Q' AND paycode IN (88, 94) AND "limit" <> 2000000; -- 194N non-filers
UPDATE tdsentriessection SET "limit" = 50000    WHERE formname = '26Q' AND paycode IN (5, 79, 80) AND "limit" <> 50000; -- 194I monthly

-- TCS thresholds (27EQ)
UPDATE tdsentriessection SET "limit" = 1000000 WHERE formname = '27EQ' AND paycode = 44 AND "limit" <> 1000000;             -- motor vehicle >10L/txn
UPDATE tdsentriessection SET "limit" = 1000000 WHERE formname = '27EQ' AND paycode BETWEEN 151 AND 160 AND "limit" <> 1000000; -- luxury goods >10L/txn
UPDATE tdsentriessection SET "limit" = 1000000 WHERE formname = '27EQ' AND paycode IN (49, 161) AND "limit" <> 1000000;     -- LRS >10L
