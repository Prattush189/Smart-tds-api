-- master__0006__newact_section_codes.sql
-- Income-tax Act 2025 (Tax Year 2026-27 / ayId >= 26) section & nature data.
--
-- 1. tdsentriessection.newcode — the numeric 2025-Act section code (1001-1092) the FVU
--    text file carries in DD field 15. Replaces the in-code eTdsR.MapSectionCodeNew /
--    MapCollectionCodeNew tables for rows that map 1:1. Rows whose new code depends on
--    the PAYEE (194C Ind/HUF-vs-other 1023/1024, bare 194I/194J defaults) keep newcode
--    NULL — the generator resolves those in code. Rows with no new-Act equivalent
--    (194F, 194IA, bullion, goods>2L/50L, services>2L, non-filer 194NF/194N-FT) also
--    stay NULL: old years keep using them, new years won't emit a code for them.
-- 2. NEW section rows the old master never had (194A senior split, REIT renting,
--    director fees, 27Q NR splits, 27EQ luxury goods, 24Q employer-type salary rows).
--    OLD ROWS ARE NEVER DELETED OR RENAMED — old-year returns still need them.
-- 3. tdsnaturenew — the 2025-Act 27Q "Nature of Remittance" list (Annexure 9, codes
--    01-19). Kept as a SEPARATE table because the legacy tdsnature codes overlap
--    (both lists use small integers); the UI picks the list by ayId.
--
-- Source: Protean "File Format_R" workbooks dated 02-07-2026 (Forms 138/140/143/144).
-- Idempotent.

ALTER TABLE tdsentriessection ADD COLUMN IF NOT EXISTS newcode varchar(4);

-- ───────────────────────────── 26Q (Form 140) — stamp newcode ─────────────────────────────
UPDATE tdsentriessection SET newcode='1004' WHERE formname='26Q' AND paycode=57;  -- 192A
UPDATE tdsentriessection SET newcode='1005' WHERE formname='26Q' AND paycode=9;   -- 194D
UPDATE tdsentriessection SET newcode='1006' WHERE formname='26Q' AND paycode=10;  -- 194H
UPDATE tdsentriessection SET newcode='1008' WHERE formname='26Q' AND paycode=79;  -- 194I(a)
UPDATE tdsentriessection SET newcode='1009' WHERE formname='26Q' AND paycode=80;  -- 194I(b)
UPDATE tdsentriessection SET newcode='1011' WHERE formname='26Q' AND paycode=61;  -- 194IC
UPDATE tdsentriessection SET newcode='1012' WHERE formname='26Q' AND paycode=40;  -- 194LA
UPDATE tdsentriessection SET newcode='1013' WHERE formname='26Q' AND paycode=83;  -- 194K
UPDATE tdsentriessection SET newcode='1014' WHERE formname='26Q' AND paycode=86;  -- 194LBA(a) interest
UPDATE tdsentriessection SET newcode='1015' WHERE formname='26Q' AND paycode=87;  -- 194LBA(b) dividend
UPDATE tdsentriessection SET newcode='1017' WHERE formname='26Q' AND paycode=56;  -- 194LBB (resident)
UPDATE tdsentriessection SET newcode='1018' WHERE formname='26Q' AND paycode=82;  -- 194LBC
UPDATE tdsentriessection SET newcode='1019' WHERE formname='26Q' AND paycode=1;   -- 193
UPDATE tdsentriessection SET newcode='1022' WHERE formname='26Q' AND paycode=6;   -- 194A (generic 5(iii))
UPDATE tdsentriessection SET newcode='1026' WHERE formname='26Q' AND paycode=84;  -- 194J(a) technical
UPDATE tdsentriessection SET newcode='1027' WHERE formname='26Q' AND paycode=85;  -- 194J(b) professional
UPDATE tdsentriessection SET newcode='1029' WHERE formname='26Q' AND paycode=58;  -- 194 dividends
UPDATE tdsentriessection SET newcode='1030' WHERE formname='26Q' AND paycode=52;  -- 194DA
UPDATE tdsentriessection SET newcode='1031' WHERE formname='26Q' AND paycode=70;  -- 194Q
UPDATE tdsentriessection SET newcode='1033' WHERE formname='26Q' AND paycode=71;  -- 194R
UPDATE tdsentriessection SET newcode='1034' WHERE formname='26Q' AND paycode=89;  -- 194RP
UPDATE tdsentriessection SET newcode='1035' WHERE formname='26Q' AND paycode=67;  -- 194O
UPDATE tdsentriessection SET newcode='1037' WHERE formname='26Q' AND paycode=72;  -- 194S
UPDATE tdsentriessection SET newcode='1038' WHERE formname='26Q' AND paycode=90;  -- 194SP
UPDATE tdsentriessection SET newcode='1058' WHERE formname='26Q' AND paycode=14;  -- 194B
UPDATE tdsentriessection SET newcode='1059' WHERE formname='26Q' AND paycode=76;  -- 194B-P
UPDATE tdsentriessection SET newcode='1060' WHERE formname='26Q' AND paycode=91;  -- 194BA
UPDATE tdsentriessection SET newcode='1061' WHERE formname='26Q' AND paycode=92;  -- 194BA-P
UPDATE tdsentriessection SET newcode='1062' WHERE formname='26Q' AND paycode=77;  -- 194BB
UPDATE tdsentriessection SET newcode='1063' WHERE formname='26Q' AND paycode=23;  -- 194G
UPDATE tdsentriessection SET newcode='1064' WHERE formname='26Q' AND paycode=93;  -- 194NC (co-op)
UPDATE tdsentriessection SET newcode='1065' WHERE formname='26Q' AND paycode=63;  -- 194N
UPDATE tdsentriessection SET newcode='1066' WHERE formname='26Q' AND paycode=22;  -- 194EE
UPDATE tdsentriessection SET newcode='1067' WHERE formname='26Q' AND paycode=75;  -- 194T
-- (194C 2/3/4 and generic 194I/194J stay NULL: payee/status-dependent, resolved in code)

-- 26Q sections that did not exist in the master at all
INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT v.paycode, v.section, v.name, 0, '26Q', v.newsection, v.newcode
FROM (VALUES
  (120, '194A',      'Interest other than securities - SENIOR CITIZEN (bank/co-op/post office)', '393(1) [Table: Sl. No. 5(ii).D(a)]', '1020'),
  (121, '194A',      'Interest other than securities - other than senior citizen (bank/co-op/post office)', '393(1) [Table: Sl. No. 5(ii).D(b)]', '1021'),
  (122, '194LBA(c)', 'Renting income from units of a business trust (REIT) to resident unit holder', '393(1) [Table: Sl. No. 4(ii)]', '1016'),
  (123, '194J(ba)',  'Remuneration / fees / commission to a director of a company', '393(1) [Table: Sl. No. 6(iii).D(b)]', '1028')
) AS v(paycode, section, name, newsection, newcode)
WHERE NOT EXISTS (SELECT 1 FROM tdsentriessection t WHERE t.formname='26Q' AND t.paycode=v.paycode);

-- ───────────────────────────── 27Q (Form 144) — stamp newcode ─────────────────────────────
UPDATE tdsentriessection SET newcode='1057' WHERE formname='27Q' AND paycode IN (11,12,13); -- 195 catch-all
UPDATE tdsentriessection SET newcode='1050' WHERE formname='27Q' AND paycode=95;  -- 196A
UPDATE tdsentriessection SET newcode='1051' WHERE formname='27Q' AND paycode=96;  -- 196B (income re units 208)
UPDATE tdsentriessection SET newcode='1053' WHERE formname='27Q' AND paycode=65;  -- 196C (interest/dividend GDR)
UPDATE tdsentriessection SET newcode='1055' WHERE formname='27Q' AND paycode=66;  -- 196D FII securities
UPDATE tdsentriessection SET newcode='1056' WHERE formname='27Q' AND paycode=101; -- 196D(1A) specified fund
UPDATE tdsentriessection SET newcode='1040' WHERE formname='27Q' AND paycode=97;  -- 194LC1 (i)/(ia)
UPDATE tdsentriessection SET newcode='1041' WHERE formname='27Q' AND paycode=98;  -- 194LC2 (ib)
UPDATE tdsentriessection SET newcode='1042' WHERE formname='27Q' AND paycode=99;  -- 194LC3 IFSC pre-Jul-2023
UPDATE tdsentriessection SET newcode='1047' WHERE formname='27Q' AND paycode=100; -- 194LBA(c) REIT rental to NR

-- 27Q sections missing from the master
INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT v.paycode, v.section, v.name, 0, '27Q', v.newsection, v.newcode
FROM (VALUES
  (130, '194E',      'Payment to non-resident sportsmen / entertainers / sports associations (sec 211)', '393(2) [Table: Sl. No. 1]', '1039'),
  (131, '194LC4',    'Interest on long-term / rupee bond listed only on IFSC, issued on or after 1-Jul-2023', '393(2) [Table: Sl. No. 4.E(b)]', '1043'),
  (132, '194LB',     'Interest from infrastructure debt fund payable to a non-resident', '393(2) [Table: Sl. No. 5]', '1044'),
  (133, '194LBA(a)', 'Interest income of a business trust distributed to non-resident unit holder', '393(2) [Table: Sl. No. 6.E(a)]', '1045'),
  (134, '194LBA(b)', 'Dividend income of a business trust distributed to non-resident unit holder', '393(2) [Table: Sl. No. 6.E(b)]', '1046'),
  (135, '194LBB',    'Income of investment-fund units payable to a non-resident', '393(2) [Table: Sl. No. 8]', '1048'),
  (136, '194LBC',    'Income from investment in a securitisation trust payable to a non-resident', '393(2) [Table: Sl. No. 9]', '1049'),
  (137, '196B',      'LTCG from transfer of units referred to in section 208 (offshore fund)', '393(2) [Table: Sl. No. 12]', '1052'),
  (138, '196C',      'LTCG from transfer of bonds / GDRs referred to in section 209', '393(2) [Table: Sl. No. 14]', '1054')
) AS v(paycode, section, name, newsection, newcode)
WHERE NOT EXISTS (SELECT 1 FROM tdsentriessection t WHERE t.formname='27Q' AND t.paycode=v.paycode);

-- ───────────────────────────── 27EQ (Form 143) — stamp newcode ─────────────────────────────
UPDATE tdsentriessection SET newcode='1068' WHERE formname='27EQ' AND paycode=30;  -- alcoholic liquor
UPDATE tdsentriessection SET newcode='1070' WHERE formname='27EQ' AND paycode=31;  -- timber forest lease
UPDATE tdsentriessection SET newcode='1071' WHERE formname='27EQ' AND paycode=32;  -- timber other
UPDATE tdsentriessection SET newcode='1072' WHERE formname='27EQ' AND paycode=33;  -- other forest produce
UPDATE tdsentriessection SET newcode='1073' WHERE formname='27EQ' AND paycode=34;  -- scrap
UPDATE tdsentriessection SET newcode='1074' WHERE formname='27EQ' AND paycode=42;  -- coal/lignite/iron
UPDATE tdsentriessection SET newcode='1075' WHERE formname='27EQ' AND paycode=44;  -- motor vehicle
UPDATE tdsentriessection SET newcode='1092' WHERE formname='27EQ' AND paycode=35;  -- mine or quarry
UPDATE tdsentriessection SET newcode='1091' WHERE formname='27EQ' AND paycode=37;  -- toll plaza
UPDATE tdsentriessection SET newcode='1090' WHERE formname='27EQ' AND paycode=38;  -- parking lot
UPDATE tdsentriessection SET newcode='1087' WHERE formname='27EQ' AND paycode=49;  -- LRS other purposes
UPDATE tdsentriessection SET newcode='1089' WHERE formname='27EQ' AND paycode=81;  -- tour package above threshold
-- (bullion 43, goods>2L 45, services>2L 46, goods>50L 48: no 2025-Act code -> newcode stays NULL)

-- 27EQ collections missing from the master (new-Act luxury goods + splits)
INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT v.paycode, v.section, v.name, 0, '27EQ', v.newsection, v.newcode
FROM (VALUES
  (150, '206C', 'TCS - Sale of tendu leaves', '394(1) [Table: Sl. No. 2]', '1069'),
  (151, '206C', 'TCS - Sale of wrist watch above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1076'),
  (152, '206C', 'TCS - Sale of art piece (antiques, painting, sculpture) above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1077'),
  (153, '206C', 'TCS - Sale of collectibles (coin, stamp) above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1078'),
  (154, '206C', 'TCS - Sale of yacht / rowing boat / canoe / helicopter above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1079'),
  (155, '206C', 'TCS - Sale of pair of sunglasses above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1080'),
  (156, '206C', 'TCS - Sale of bag (handbag, purse) above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1081'),
  (157, '206C', 'TCS - Sale of pair of shoes above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1082'),
  (158, '206C', 'TCS - Sale of sportswear and equipment (golf kit, ski-wear) above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1083'),
  (159, '206C', 'TCS - Sale of home theatre system above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1084'),
  (160, '206C', 'TCS - Sale of horse for racing in race clubs / polo above threshold', '394(1) [Table: Sl. No. 6.D(b)]', '1085'),
  (161, '206C', 'TCS - LRS remittance for education or medical treatment above threshold', '394(1) [Table: Sl. No. 7.D(a)]', '1086'),
  (162, '206C', 'TCS - Overseas tour programme package up to threshold', '394(1) [Table: Sl. No. 8.D(a)]', '1088')
) AS v(paycode, section, name, newsection, newcode)
WHERE NOT EXISTS (SELECT 1 FROM tdsentriessection t WHERE t.formname='27EQ' AND t.paycode=v.paycode);

-- ───────────────────────────── 24Q (Form 138) — employer-type salary sections ─────────────
UPDATE tdsentriessection SET newcode='1002' WHERE formname='24Q' AND paycode=21;  -- generic salary -> non-Govt default

INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT v.paycode, v.section, v.name, 0, '24Q', '392', v.newcode
FROM (VALUES
  (140, '192', 'Salary - State Government employees',            '1001'),
  (141, '192', 'Salary - Other than Government employees',       '1002'),
  (142, '192', 'Salary - Union (Central) Government employees',  '1003')
) AS v(paycode, section, name, newcode)
WHERE NOT EXISTS (SELECT 1 FROM tdsentriessection t WHERE t.formname='24Q' AND t.paycode=v.paycode);

-- ───────────────── 27Q Nature of Remittance, 2025-Act list (Annexure 9) ────────────────────
-- Separate table: legacy tdsnature codes overlap numerically and are still needed for
-- ayId < 26. The UI selects tdsnature (old) or tdsnaturenew (new) by the return's year.
CREATE TABLE IF NOT EXISTS tdsnaturenew (
    code       integer PRIMARY KEY,
    particular varchar(200) NOT NULL
);

INSERT INTO tdsnaturenew (code, particular) VALUES
  (1,  'Winnings from lottery or crossword puzzle, card game, gambling or betting of any form'),
  (2,  'Winnings from online games'),
  (3,  'Winnings from horse race'),
  (4,  'Payments to non-resident sportsmen or entertainer / sports associations or institution'),
  (5,  'Interest income'),
  (6,  'Dividend income referred to in section 207(1) [Table: Sl. No. 1]'),
  (7,  'Dividend income referred to in section 207(1) [Table: Sl. No. 2]'),
  (8,  'Income by way of renting or leasing or letting out any real estate asset'),
  (9,  'Investment income'),
  (10, 'Long term capital gains referred to in section 214 [Table: Sl. No. 2] or 197(1)'),
  (11, 'Long term capital gains referred to in section 198 exceeding one lakh twenty-five thousand rupees'),
  (12, 'Long term capital gains referred to in section 214 [Table: Sl. No. 1]'),
  (13, 'Short term capital gains referred to in section 196'),
  (14, 'Short term capital gains (not being short term capital gains referred to in section 196)'),
  (15, 'Commission'),
  (16, 'Fee for technical services / included services'),
  (17, 'Royalty'),
  (18, 'Cash withdrawal'),
  (19, 'Other income')
ON CONFLICT (code) DO UPDATE SET particular = EXCLUDED.particular;
