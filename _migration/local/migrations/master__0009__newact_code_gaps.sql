-- master__0009__newact_code_gaps.sql
-- Follow-ups from the section-picker review:
-- 1. 24Q was missing 1032 — "Deduction of tax in case of specified senior citizens"
--    (old 194P, 393(1) [Table: Sl. No. 8(iii)]). Slab-based like salary -> no tdsrate rows.
-- 2. Stamp display newcodes on generic rows whose FVU fallback is deterministic anyway:
--    194LBA generic -> 1014 (interest default), bare 194I -> 1009, bare 194J -> 1027.
--    194C stays NULL on purpose (payee-dependent 1023/1024); 194LAA stays NULL (no
--    2025-Act code in Form 140 — property TDS is the 26QB channel).
-- Idempotent.

INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT 143, '194P', 'Deduction of tax in case of specified senior citizens (pension + interest via specified bank)', 0, '24Q', '393(1) [Table: Sl. No. 8(iii)]', '1032'
WHERE NOT EXISTS (SELECT 1 FROM tdsentriessection t WHERE t.formname='24Q' AND t.paycode=143);

UPDATE tdsentriessection SET newcode='1014' WHERE formname='26Q' AND paycode=53 AND newcode IS NULL; -- 194LBA generic
UPDATE tdsentriessection SET newcode='1009' WHERE formname='26Q' AND paycode=5  AND newcode IS NULL; -- bare 194I (rent default D(b))
UPDATE tdsentriessection SET newcode='1027' WHERE formname='26Q' AND paycode=8  AND newcode IS NULL; -- bare 194J (professional default)
