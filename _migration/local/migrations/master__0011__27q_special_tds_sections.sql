-- master__0011__27q_special_tds_sections.sql
--
-- Audit Part 1, finding M10: the 27Q (Form 144) master was missing the 2025-Act
-- special-TDS section codes 1004 and 1058-1067. These sections CAN apply to a
-- non-resident deductee (a NR lottery/online-game/horse-race winner, a NR lottery
-- agent, a NR cash withdrawal, a NR NSS payout, a NR / corporate partner, a NR PF
-- withdrawal), and the FVU generator already treats them as Form-144-valid
-- (eTdsR.Is27QYEligible / the 27Q reason matrices list 1004/1058/1059/1062/1063/
-- 1066/1067). But because no tdsentriessection row carried FormName '27Q' for
-- them, GetByPayCode('27Q') never surfaced them and a NR deductee could not be
-- booked under these sections.
--
-- FIX: add the 11 missing rows as NEW 27Q paycodes (170-180 — the paycode space
-- above 162 is free) carrying the correct newcode, plus the NR rate rows.
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ ⚠  REVIEW BEFORE SHIPPING — the RATES and per-section tsId 3/4 scope below  │
-- │    are the flat statutory rates (residency-independent for these sections),│
-- │    but they are ASSERTED here, not cloned, because the resident equivalents │
-- │    either have no ayid-26 rate row (in-kind / special-handling sections) or │
-- │    the rate is set in a different migration. Notably:                       │
-- │      • 194G (1063): 2% — matches the resident 194G rate (paycode 23), which │
-- │        master__0007 already corrects from the seed's 10% to 2% for ayid>=26.│
-- │      • surcharge = 0 for all (NR slab-based, entered per-entry; cess auto). │
-- │    Confirm each rate against the current TY2026-27 chart before release.    │
-- └──────────────────────────────────────────────────────────────────────────┘
--
-- Idempotent (NOT EXISTS on paycode). Forward-only.

-- ── 27Q section rows (Form 144) ──────────────────────────────────────────────
INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT v.paycode, v.section, v.name, v."limit", '27Q', v.newsection, v.newcode
FROM (VALUES
  (170, '192A',    'Accumulated PF balance paid to a non-resident (u/s 392(7))',                    50000, '392(7)',                  '1004'),
  (171, '194B',    'Winnings from lottery / crossword / card game paid to a non-resident',           10000, '393(3) [Sl. No. 1]',      '1058'),
  (172, '194B-P',  'Winnings from lottery to a non-resident (consideration in kind / cash short)',       0, '393(3) [Sl. No. 1 Note 2]','1059'),
  (173, '194BA',   'Net winnings from online games paid to a non-resident',                              0, '393(3) [Sl. No. 2]',      '1060'),
  (174, '194BA-P', 'Net winnings from online games to a non-resident (in kind / cash short)',            0, '393(3) [Sl. No. 2 Note 2]','1061'),
  (175, '194BB',   'Winnings from horse race paid to a non-resident',                                10000, '393(3) [Sl. No. 3]',      '1062'),
  (176, '194G',    'Commission on sale of lottery tickets to a non-resident',                        20000, '393(3) [Sl. No. 4]',      '1063'),
  (177, '194NC',   'Cash withdrawal from a co-operative society (non-resident)',                         0, '393(3) [Sl. No. 5.D(a)]', '1064'),
  (178, '194N',    'Cash withdrawal paid to a non-resident (u/s 194N)',                                  0, '393(3) [Sl. No. 5.D(b)]', '1065'),
  (179, '194EE',   'NSS payment to a non-resident (u/s 194EE)',                                       2500, '393(3) [Sl. No. 6]',      '1066'),
  (180, '194T',    'Partner remuneration / interest paid to a non-resident (u/s 194T)',              20000, '393(3) [Sl. No. 7]',      '1067')
) AS v(paycode, section, name, "limit", newsection, newcode)
WHERE NOT EXISTS (
    SELECT 1 FROM tdsentriessection t WHERE t.paycode = v.paycode
);

-- ── NR rate rows (tsId 3 = NR non-company, 4 = NR foreign company) ────────────
-- 192A (PF) and 194EE (NSS) are individual-only instruments → tsId 3 only.
-- The rest can have a corporate collectee → tsId 3 and 4 (same base rate).
INSERT INTO tdsrate (ayid, tsid, paycode, rate, surch, "limit")
SELECT 26, v.tsid, v.paycode, v.rate, 0.00, 0
FROM (VALUES
  -- 192A PF 10% — non-company only
  (170, 3, 10.00),
  -- 194B lottery 30%
  (171, 3, 30.00), (171, 4, 30.00),
  -- 194B-P lottery in kind 30% (generator forces DD tax fields to 0 for in-kind)
  (172, 3, 30.00), (172, 4, 30.00),
  -- 194BA online game 30%
  (173, 3, 30.00), (173, 4, 30.00),
  -- 194BA-P online game in kind 30%
  (174, 3, 30.00), (174, 4, 30.00),
  -- 194BB horse race 30%
  (175, 3, 30.00), (175, 4, 30.00),
  -- 194G lottery commission 2% (matches resident pc23 after master__0007)
  (176, 3, 2.00), (176, 4, 2.00),
  -- 194NC cash withdrawal (co-op) 2%
  (177, 3, 2.00), (177, 4, 2.00),
  -- 194N cash withdrawal 2%
  (178, 3, 2.00), (178, 4, 2.00),
  -- 194EE NSS 10% — non-company only
  (179, 3, 10.00),
  -- 194T partner remuneration 10%
  (180, 3, 10.00), (180, 4, 10.00)
) AS v(paycode, tsid, rate)
WHERE NOT EXISTS (
    SELECT 1 FROM tdsrate t
    WHERE t.ayid = 26 AND t.tsid = v.tsid AND t.paycode = v.paycode
);
