-- master__0010__rate_audit_fixes.sql
-- TY2026-27 rate audit (verified vs TDSMAN/TaxGuru charts 2026-07):
-- 1. Corrections, guarded on the stale value so deliberate manual edits survive:
--    194H 5% -> 2%; 194O 1% -> 0.1%; 194EE 20% -> 10%; TCS coal/lignite/iron 1% -> 2%;
--    TCS timber (both modes) and other forest produce -> flat 2%.
-- 2. 27Q 194LC3 moves off paycode 99 (shared with 26Q 194E, which needs 20% while
--    LC3 needs 4% - tdsrate has no form column, so a shared paycode cannot carry
--    both). New paycode 139; year__0005 relinks any existing 27Q entries.
-- 3. Missing ay-26 rate rows for sections that had none (194BB 30, 194K 10,
--    194LBC 10, 194BA 30, 194NC 2, 194LBA(a)/(b) 10, 196A 20, 196B 10, LC1/LC2 5,
--    LBA(c)-NR 30/35, 196D(1A) 10, LC3 4).
-- Idempotent.

UPDATE tdsrate SET rate = 2.00  WHERE ayid >= 26 AND paycode = 10 AND rate = 5.00;   -- 194H
UPDATE tdsrate SET rate = 0.10  WHERE ayid >= 26 AND paycode = 67 AND rate = 1.00;   -- 194O
UPDATE tdsrate SET rate = 10.00 WHERE ayid >= 26 AND paycode = 22 AND rate = 20.00;  -- 194EE
UPDATE tdsrate SET rate = 2.00  WHERE ayid >= 26 AND paycode = 42 AND rate = 1.00;   -- TCS coal/lignite/iron
UPDATE tdsrate SET rate = 2.00  WHERE ayid >= 26 AND paycode IN (31, 32, 33) AND rate <> 2.00; -- TCS timber x2 + forest produce

-- 194LC3: own paycode (99 -> 139), keeping the 26Q 194E rows untouched.
UPDATE tdsentriessection SET paycode = 139 WHERE formname = '27Q' AND paycode = 99 AND section = '194LC3';

INSERT INTO tdsrate (ayid, tsid, paycode, rate, surch, "limit")
SELECT v.* FROM (VALUES
  (26, 1, 77, 30.00, 0.00, 0), (26, 2, 77, 30.00, 0.00, 0), (26, 5, 77, 30.00, 0.00, 0),   -- 194BB
  (26, 1, 83, 10.00, 0.00, 0), (26, 2, 83, 10.00, 0.00, 0), (26, 5, 83, 10.00, 0.00, 0),   -- 194K
  (26, 1, 82, 10.00, 0.00, 0), (26, 2, 82, 10.00, 0.00, 0), (26, 5, 82, 10.00, 0.00, 0),   -- 194LBC (resident)
  (26, 1, 91, 30.00, 0.00, 0), (26, 2, 91, 30.00, 0.00, 0), (26, 5, 91, 30.00, 0.00, 0),   -- 194BA
  (26, 1, 93, 2.00, 0.00, 0),  (26, 2, 93, 2.00, 0.00, 0),                                  -- 194NC
  (26, 1, 86, 10.00, 0.00, 0), (26, 2, 86, 10.00, 0.00, 0), (26, 5, 86, 10.00, 0.00, 0),   -- 194LBA(a)
  (26, 1, 87, 10.00, 0.00, 0), (26, 2, 87, 10.00, 0.00, 0), (26, 5, 87, 10.00, 0.00, 0),   -- 194LBA(b)
  (26, 3, 95, 20.00, 0.00, 0), (26, 4, 95, 20.00, 0.00, 0),                                  -- 196A
  (26, 3, 96, 10.00, 0.00, 0), (26, 4, 96, 10.00, 0.00, 0),                                  -- 196B (income)
  (26, 3, 97, 5.00, 0.00, 0),  (26, 4, 97, 5.00, 0.00, 0),                                   -- 194LC1
  (26, 3, 98, 5.00, 0.00, 0),  (26, 4, 98, 5.00, 0.00, 0),                                   -- 194LC2
  (26, 3, 100, 30.00, 0.00, 0),(26, 4, 100, 35.00, 0.00, 0),                                 -- 194LBA(c) NR
  (26, 3, 101, 10.00, 0.00, 0),(26, 4, 101, 10.00, 0.00, 0),                                 -- 196D(1A)
  (26, 3, 139, 4.00, 0.00, 0), (26, 4, 139, 4.00, 0.00, 0)                                   -- 194LC3 (IFSC pre-Jul-23)
) AS v(ayid, tsid, paycode, rate, surch, "limit")
WHERE NOT EXISTS (
  SELECT 1 FROM tdsrate t WHERE t.ayid = v.ayid AND t.tsid = v.tsid AND t.paycode = v.paycode
);
