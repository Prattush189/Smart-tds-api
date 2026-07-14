-- master__0005__2025act_consolidated.sql
-- Everything the installer template lacks: TRACES requests table, 2025-Act section/nature/country masters, TY2026-27 rate corrections, TCS collectee-type rows.
-- Consolidation of: 0005, 0006, 0007, 0008, 0009, 0010, 0011 - all idempotent; re-runs are no-ops on DBs that already ran the originals.

-- ============================================================
-- >> from master__0005__traces_requests.sql
-- ============================================================
-- master__0005__traces_requests.sql
-- TRACES download-request register: one row per Form 16 / 16A / 27D / Conso /
-- Justification request raised on TRACES, tracking the request number and (after the
-- file is downloaded) the saved file path. Lives in MASTER (not a year DB) because the
-- TRACES automation form lets the user pick ANY financial year independent of the open
-- assessment year, so a payer's requests must be viewable together in one grid.
-- Tenant-isolated by subcode, same pattern as bankdetails/assesseerep in master__0001.
-- Column names are all-lowercase no-underscore to match the existing schema convention
-- (clean case-insensitive mapping to the camelCase TracesRequest entity).
-- Idempotent: safe to run on new and existing installs (migrate-local.ps1).
CREATE TABLE IF NOT EXISTS tracesrequest (
    id           serial PRIMARY KEY,
    subcode      integer      NOT NULL,
    tan          varchar(10),
    requesttype  varchar(12)  NOT NULL,   -- Form16 / Form16a / Form27d / Conso / Justi
    frmno        varchar(6),              -- 24Q / 26Q / 27Q / 27EQ
    finyr        varchar(7)   NOT NULL,   -- e.g. 2025-26
    quarter      varchar(4),              -- Q1..Q4
    requestno    varchar(40),             -- number returned by TRACES
    requestdate  date,
    status       varchar(16)  NOT NULL DEFAULT 'Requested',  -- Requested/Available/Downloaded/Failed
    filepath     text,                    -- where the downloaded file was saved
    downloadedon timestamptz,
    remarks      text,
    createdon    timestamptz  NOT NULL DEFAULT now(),
    updatedon    timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_tracesrequest_subcode ON tracesrequest (subcode);

-- Row-level security: a row is visible/writable only when its subcode belongs to the
-- current tenant (app.prodkey, set per-connection by DbConnectionFactory). app_owns_subcode
-- is created + granted to smarttds_app in master__0001. Grants on this new table are
-- (re)applied by migrate-local.ps1's least-privilege step after the migration runs.
ALTER TABLE tracesrequest ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_tracesrequest ON tracesrequest;
CREATE POLICY tenant_tracesrequest ON tracesrequest
    USING (app_owns_subcode(subcode))
    WITH CHECK (app_owns_subcode(subcode));

-- ============================================================
-- >> from master__0006__newact_section_codes.sql
-- ============================================================
-- master__0006__newact_section_codes.sql
-- Income-tax Act 2025 (Tax Year 2026-27 / ayId >= 26) section & nature data.
--
-- 1. tdsentriessection.newcode â€” the numeric 2025-Act section code (1001-1092) the FVU
--    text file carries in DD field 15. Replaces the in-code eTdsR.MapSectionCodeNew /
--    MapCollectionCodeNew tables for rows that map 1:1. Rows whose new code depends on
--    the PAYEE (194C Ind/HUF-vs-other 1023/1024, bare 194I/194J defaults) keep newcode
--    NULL â€” the generator resolves those in code. Rows with no new-Act equivalent
--    (194F, 194IA, bullion, goods>2L/50L, services>2L, non-filer 194NF/194N-FT) also
--    stay NULL: old years keep using them, new years won't emit a code for them.
-- 2. NEW section rows the old master never had (194A senior split, REIT renting,
--    director fees, 27Q NR splits, 27EQ luxury goods, 24Q employer-type salary rows).
--    OLD ROWS ARE NEVER DELETED OR RENAMED â€” old-year returns still need them.
-- 3. tdsnaturenew â€” the 2025-Act 27Q "Nature of Remittance" list (Annexure 9, codes
--    01-19). Kept as a SEPARATE table because the legacy tdsnature codes overlap
--    (both lists use small integers); the UI picks the list by ayId.
--
-- Source: Protean "File Format_R" workbooks dated 02-07-2026 (Forms 138/140/143/144).
-- Idempotent.

ALTER TABLE tdsentriessection ADD COLUMN IF NOT EXISTS newcode varchar(4);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ 26Q (Form 140) â€” stamp newcode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ 27Q (Form 144) â€” stamp newcode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ 27EQ (Form 143) â€” stamp newcode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ 24Q (Form 138) â€” employer-type salary sections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
UPDATE tdsentriessection SET newcode='1002' WHERE formname='24Q' AND paycode=21;  -- generic salary -> non-Govt default

INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT v.paycode, v.section, v.name, 0, '24Q', '392', v.newcode
FROM (VALUES
  (140, '192', 'Salary - State Government employees',            '1001'),
  (141, '192', 'Salary - Other than Government employees',       '1002'),
  (142, '192', 'Salary - Union (Central) Government employees',  '1003')
) AS v(paycode, section, name, newcode)
WHERE NOT EXISTS (SELECT 1 FROM tdsentriessection t WHERE t.formname='24Q' AND t.paycode=v.paycode);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ 27Q Nature of Remittance, 2025-Act list (Annexure 9) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- ============================================================
-- >> from master__0007__newact_rates_countries.sql
-- ============================================================
-- master__0007__newact_rates_countries.sql
-- Rates for the 2025-Act sections added by master__0006, and the Annexure-10 country
-- list for 27Q (ayId >= 26).
--
-- RATES (tdsrate, ayid 26): verified online against TY2026-27 charts (TDSMAN / TaxGuru,
-- 2026-07). Mirrors the tsid patterns of sibling paycodes. Existing rows are never
-- modified. Salary rows (paycodes 140-142) get no rate rows - slab-based.
--   194A senior/non-senior: 10% (same rate, split is disclosure-only)
--   REIT renting to resident 10%; director fees 10%; 194E 20%; IFSC bond >=Jul-23 9%;
--   194LB 5%; 194LBA-NR interest 5% / dividend 10%; 194LBB/LBC-NR 30% (35% company);
--   196B/196C LTCG 12.5%; tendu 2%; luxury goods 1% (same as goods > threshold);
--   LRS education/medical 2%; overseas tour package flat 2%.
--
-- COUNTRIES: the 2025-Act Annexure 10 list is a SEQUENTIAL alphabetical list
-- (Afghanistan=1 ... 286) - incompatible with the legacy dialing-code list in
-- `country` (India=91, USA=2). Kept in a SEPARATE table countrynew; payees keep
-- storing the OLD code, the FVU generator translates old->new BY NAME for ayId>=26.
-- Idempotent.

INSERT INTO tdsrate (ayid, tsid, paycode, rate, surch, "limit")
SELECT v.* FROM (VALUES
  -- 26Q new sections (tsid 1/2/5)
  (26, 1, 120, 10.00, 2.50, 0), (26, 2, 120, 10.00, 10.00, 0), (26, 5, 120, 10.00, 2.50, 0),
  (26, 1, 121, 10.00, 2.50, 0), (26, 2, 121, 10.00, 10.00, 0), (26, 5, 121, 10.00, 2.50, 0),
  (26, 1, 122, 10.00, 0.00, 0), (26, 2, 122, 10.00, 0.00, 0),  (26, 5, 122, 10.00, 0.00, 0),
  (26, 1, 123, 10.00, 2.50, 0), (26, 2, 123, 10.00, 10.00, 0), (26, 5, 123, 10.00, 2.50, 0),
  -- 27Q new sections (NR: tsid 3 = non-company, 4 = company)
  (26, 1, 130, 20.00, 0.00, 0), (26, 3, 130, 20.00, 0.00, 0), (26, 4, 130, 20.00, 0.00, 0),
  (26, 3, 131, 9.00, 0.00, 0),  (26, 4, 131, 9.00, 0.00, 0),
  (26, 3, 132, 5.00, 0.00, 0),  (26, 4, 132, 5.00, 0.00, 0),
  (26, 3, 133, 5.00, 0.00, 0),  (26, 4, 133, 5.00, 0.00, 0),
  (26, 3, 134, 10.00, 0.00, 0), (26, 4, 134, 10.00, 0.00, 0),
  (26, 3, 135, 30.00, 0.00, 0), (26, 4, 135, 35.00, 2.00, 0),
  (26, 3, 136, 30.00, 0.00, 0), (26, 4, 136, 35.00, 2.00, 0),
  (26, 3, 137, 12.50, 0.00, 0), (26, 4, 137, 12.50, 0.00, 0),
  (26, 3, 138, 12.50, 0.00, 0), (26, 4, 138, 12.50, 0.00, 0),
  -- 27EQ new collections (tsid 1/2/5)
  (26, 1, 150, 2.00, 0.00, 0), (26, 2, 150, 2.00, 0.00, 0), (26, 5, 150, 2.00, 0.00, 0),
  (26, 1, 151, 1.00, 0.00, 0), (26, 2, 151, 1.00, 0.00, 0), (26, 5, 151, 1.00, 0.00, 0),
  (26, 1, 152, 1.00, 0.00, 0), (26, 2, 152, 1.00, 0.00, 0), (26, 5, 152, 1.00, 0.00, 0),
  (26, 1, 153, 1.00, 0.00, 0), (26, 2, 153, 1.00, 0.00, 0), (26, 5, 153, 1.00, 0.00, 0),
  (26, 1, 154, 1.00, 0.00, 0), (26, 2, 154, 1.00, 0.00, 0), (26, 5, 154, 1.00, 0.00, 0),
  (26, 1, 155, 1.00, 0.00, 0), (26, 2, 155, 1.00, 0.00, 0), (26, 5, 155, 1.00, 0.00, 0),
  (26, 1, 156, 1.00, 0.00, 0), (26, 2, 156, 1.00, 0.00, 0), (26, 5, 156, 1.00, 0.00, 0),
  (26, 1, 157, 1.00, 0.00, 0), (26, 2, 157, 1.00, 0.00, 0), (26, 5, 157, 1.00, 0.00, 0),
  (26, 1, 158, 1.00, 0.00, 0), (26, 2, 158, 1.00, 0.00, 0), (26, 5, 158, 1.00, 0.00, 0),
  (26, 1, 159, 1.00, 0.00, 0), (26, 2, 159, 1.00, 0.00, 0), (26, 5, 159, 1.00, 0.00, 0),
  (26, 1, 160, 1.00, 0.00, 0), (26, 2, 160, 1.00, 0.00, 0), (26, 5, 160, 1.00, 0.00, 0),
  (26, 1, 161, 2.00, 0.00, 0), (26, 2, 161, 2.00, 0.00, 0), (26, 5, 161, 2.00, 0.00, 0),
  (26, 1, 162, 2.00, 0.00, 0), (26, 2, 162, 2.00, 0.00, 0), (26, 5, 162, 2.00, 0.00, 0)
) AS v(ayid, tsid, paycode, rate, surch, "limit")
WHERE NOT EXISTS (
  SELECT 1 FROM tdsrate t WHERE t.ayid = v.ayid AND t.tsid = v.tsid AND t.paycode = v.paycode
);

-- 2025-Act Annexure 10 country list (27Q "Country of remittance" for ayId >= 26)
CREATE TABLE IF NOT EXISTS countrynew (
    code integer PRIMARY KEY,
    name varchar(120) NOT NULL
);

INSERT INTO countrynew (code, name) VALUES
  (1, 'AFGHANISTAN'),
  (2, 'AKROTIRI'),
  (3, 'ALBANIA'),
  (4, 'ALGERIA'),
  (5, 'AMERICAN SAMOA'),
  (6, 'ANDORRA'),
  (7, 'ANGOLA'),
  (8, 'ANGUILLA'),
  (9, 'ANTARCTICA'),
  (10, 'ANTIGUA AND BARBUDA'),
  (11, 'ARGENTINA'),
  (12, 'ARMENIA'),
  (13, 'ARUBA'),
  (14, 'ASHMORE AND CARTIER ISLANDS'),
  (15, 'AUSTRALIA'),
  (16, 'AUSTRIA'),
  (17, 'AZERBAIJAN'),
  (18, 'BAHRAIN'),
  (19, 'BAILIWICK OF GUERNSEY'),
  (20, 'BAILIWICK OF JERSEY'),
  (21, 'BAKER ISLAND'),
  (22, 'BANGLADESH'),
  (23, 'BARBADOS'),
  (24, 'BELARUS'),
  (25, 'BELGIUM'),
  (26, 'BELIZE'),
  (27, 'BENIN PORTO'),
  (28, 'BERMUDA'),
  (29, 'BHUTAN'),
  (30, 'BOLIVIA'),
  (31, 'BOSNIAAND HERZEGOVINA'),
  (32, 'BOTSWANA'),
  (33, 'BOUVET ISLAND'),
  (34, 'BRAZIL'),
  (35, 'BRITISH INDIAN OCEAN TERRITORY'),
  (36, 'BRUNEI'),
  (37, 'BULGARIA'),
  (38, 'BURKINA FASO'),
  (39, 'BURUNDI'),
  (40, 'CAMBODIA'),
  (41, 'CAMEROON'),
  (42, 'CANADA'),
  (43, 'CAPE VERDE'),
  (44, 'CAYMAN ISLANDS'),
  (45, 'CENTRAL AFRICAN REPUBLIC'),
  (46, 'CHAD'),
  (47, 'CHILE'),
  (48, 'CHINA'),
  (49, 'CHRISTMAS ISLAND'),
  (50, 'CLIPPERTON ISLAND'),
  (51, 'COCOS (KEELING) ISLANDS'),
  (52, 'COLOMBIA'),
  (53, 'COMMONWEALTH OF PUERTO RICO'),
  (54, 'COMMONWEALTH OF THE NORTHERN MARIANA ISLANDS'),
  (55, 'COMOROS'),
  (56, 'CONGO,DEMOCRATIC REPUBLIC OF THE'),
  (57, 'CONGO,REPUBLIC OF THE'),
  (58, 'COOK ISLANDS'),
  (59, 'CORAL SEA ISLANDS'),
  (60, 'CORAL SEA ISLANDS TERRITORY'),
  (61, 'COSTA RICA'),
  (62, 'COTE D''IVOIRE'),
  (63, 'CROATIA'),
  (64, 'CUBA'),
  (65, 'CYPRUS'),
  (66, 'CZECH REPUBLIC'),
  (67, 'DENMARK'),
  (68, 'DEPARTMENTAL COLLECTIVITY OF MAYOTTE'),
  (69, 'DHEKELIA'),
  (70, 'DJIBOUTI'),
  (71, 'DOMINICA'),
  (72, 'DOMINICAN REPUBLIC'),
  (73, 'EAST TIMOR (TIMORLASTE)'),
  (74, 'ECUADOR'),
  (75, 'EGYPT'),
  (76, 'ELSALVADOR'),
  (77, 'EQUATORIAL GUINEA'),
  (78, 'ERITREA'),
  (79, 'ESTONIA'),
  (80, 'ETHIOPIA'),
  (81, 'FALKLAND ISLANDS (ISLAS MALVINAS)'),
  (82, 'FAROE ISLANDS'),
  (83, 'FIJI'),
  (84, 'FINLAND'),
  (85, 'FRANCE'),
  (86, 'FRENCH GUIANA'),
  (87, 'FRENCH POLYNESIA'),
  (88, 'FRENCH SOUTHERN ISLANDS'),
  (89, 'GABON'),
  (90, 'GEORGIA'),
  (91, 'GERMANY'),
  (92, 'GEURNSEY'),
  (93, 'GHANA'),
  (94, 'GIBRALTAR'),
  (95, 'GREECE'),
  (96, 'GREENLAND'),
  (97, 'GRENADA'),
  (98, 'GUADELOUPE'),
  (100, 'GUAM'),
  (101, 'GUATEMALA'),
  (102, 'GUERNSEY'),
  (103, 'GUINEA'),
  (104, 'GUINEABISSAU'),
  (105, 'GUYANA'),
  (106, 'HAITI'),
  (107, 'HEARD ISLAND AND MCDONALD ISLANDS'),
  (108, 'HONDURAS'),
  (109, 'HONG KONG'),
  (110, 'HOWLAND ISLAND'),
  (111, 'HUNGARY'),
  (112, 'ICELAND'),
  (113, 'INDIA'),
  (114, 'INDONESIA'),
  (115, 'IRAN'),
  (116, 'IRAQ'),
  (117, 'IRELAND'),
  (118, 'ISLE OF MAN'),
  (119, 'ISRAEL'),
  (120, 'ITALY'),
  (121, 'JAMAICA'),
  (122, 'JAN MAYEN'),
  (123, 'JAPAN'),
  (124, 'JARVIS ISLAND'),
  (125, 'JERSEY'),
  (126, 'JOHNSTON ATOLL'),
  (127, 'JORDAN'),
  (128, 'KAZAKHSTAN'),
  (129, 'KENYA'),
  (130, 'KINGMAN REEF'),
  (131, 'KIRIBATI'),
  (132, 'KOREA, NORTH'),
  (133, 'KOREA, SOUTH'),
  (134, 'KOSOVO'),
  (135, 'KUWAIT'),
  (136, 'KYRGYZSTAN'),
  (137, 'LAOS'),
  (138, 'LATVIA'),
  (139, 'LEBANON'),
  (140, 'LESOTHO'),
  (141, 'LIBERIA'),
  (142, 'LIBYA'),
  (143, 'LIECHTENSTEIN'),
  (144, 'LITHUANIA'),
  (145, 'LUXEMBOURG'),
  (146, 'MACAU'),
  (147, 'MACEDONIA'),
  (148, 'MADAGASCAR'),
  (149, 'MALAWI'),
  (150, 'MALAYSIA'),
  (151, 'MALAYSIA (LABUAN)'),
  (152, 'MALDIVES'),
  (153, 'MALI'),
  (154, 'MALTA'),
  (155, 'MARSHALLISLANDS'),
  (156, 'MARTINIQUE'),
  (157, 'MAURITANIA'),
  (158, 'MAURITIUS'),
  (159, 'MAYOTTE'),
  (160, 'UNITED MEXICAN STATES'),
  (161, 'MICRONESIA, FEDERATED STATES OF'),
  (162, 'MIDWAY ISLANDS'),
  (163, 'MOLDOVA'),
  (164, 'MONACO'),
  (165, 'MONGOLIA'),
  (166, 'MONTENEGRO'),
  (167, 'MONTSERRAT'),
  (168, 'MOROCCO'),
  (169, 'MOZAMBIQUE'),
  (170, 'MYANMAR (BURMA)'),
  (171, 'NAMIBIA'),
  (172, 'NAURU'),
  (173, 'NAVASSA ISLAND'),
  (174, 'NEPAL'),
  (175, 'NETHERLANDS'),
  (176, 'NETHERLANDS ANTILLES'),
  (177, 'NEW CALEDONIA'),
  (178, 'NEWZEALAND'),
  (179, 'NICARAGUA'),
  (180, 'NIGER'),
  (181, 'NIGERIA'),
  (182, 'NIUE'),
  (183, 'NORFOLK ISLAND'),
  (184, 'NORTHERN MARIANA ISLANDS'),
  (185, 'NORWAY'),
  (186, 'OMAN'),
  (187, 'PAKISTAN'),
  (188, 'PALAU'),
  (189, 'PALMYRA ATOLL'),
  (190, 'PANAMA'),
  (191, 'PAPUA NEW GUINEA'),
  (192, 'PARACEL ISLANDS'),
  (193, 'PARAGUAY'),
  (194, 'PERU'),
  (195, 'PHILIPPINES'),
  (196, 'PITCAIRN ISLANDS'),
  (197, 'PITCAIRN, HENDERSON, DUCIE, AND OENO ISLANDS'),
  (198, 'POLAND'),
  (199, 'PORTUGAL'),
  (200, 'PUERTO RICO'),
  (201, 'QATAR'),
  (202, 'REUNION'),
  (203, 'ROMANIA'),
  (204, 'RUSSIA'),
  (205, 'RWANDA'),
  (206, 'SAINT BARTHELEMY'),
  (207, 'SAINT HELENA'),
  (208, 'SAINT KITTS AND NEVIS'),
  (209, 'SAINT LUCIA'),
  (210, 'SAINT MARTIN'),
  (211, 'SAINT PIERRE AND MIQUELON'),
  (212, 'SAINT VINCENT AND THE GRENADINES'),
  (213, 'SAMOA'),
  (214, 'SANMARINO'),
  (215, 'SAO TOME AND PRINCIPE'),
  (216, 'SAUDI ARABIA'),
  (217, 'SENEGAL'),
  (218, 'SERBIA'),
  (219, 'SEYCHELLES'),
  (220, 'SIERRA LEONE'),
  (221, 'SINGAPORE'),
  (222, 'SLOVAKIA'),
  (223, 'SLOVENIA'),
  (224, 'SOLOMON ISLANDS'),
  (225, 'SOMALIA'),
  (226, 'SOUTH AFRICA'),
  (227, 'SOUTH GEORGIA AND SOUTH SANDWICH ISLANDS'),
  (228, 'SPRATLY ISLANDS'),
  (229, 'SPAIN'),
  (230, 'SRI LANKA'),
  (231, 'ST. VINCENT & GRENADINES'),
  (232, 'SUDAN'),
  (233, 'SURINAME'),
  (234, 'SVALBARD'),
  (235, 'SWAZILAND'),
  (236, 'SWEDEN'),
  (237, 'SWITZERLAND'),
  (238, 'SYRIA'),
  (239, 'TAIWAN'),
  (240, 'TAJIKISTAN'),
  (241, 'TANZANIA'),
  (242, 'TERRITORIAL COLLECTIVITY OF ST. PIERRE & MIQUELON'),
  (243, 'TERRITORY OF AMERICAN SAMOA'),
  (244, 'TERRITORY OF ASHMORE AND CARTIER ISLANDS'),
  (245, 'TERRITORY OF CHRISTMAS ISLAND'),
  (246, 'TERRITORY OF COCOS (KEELING) ISLANDS'),
  (247, 'TERRITORY OF GUAM'),
  (248, 'TERRITORY OF HEARD ISLAND & MCDONALD ISLANDS'),
  (249, 'TERRITORY OF NORFOLK ISLAND'),
  (250, 'THAILAND'),
  (251, 'THE BAHAMAS'),
  (252, 'THE GAMBIA'),
  (253, 'TOGO'),
  (254, 'TOKELAU'),
  (255, 'TONGA'),
  (256, 'TRINIDAD AND TOBAGO'),
  (257, 'TUNISIA'),
  (258, 'TURKEY'),
  (259, 'TURKMENISTAN'),
  (260, 'TURKS AND CAICOS ISLANDS'),
  (261, 'TUVALU'),
  (262, 'UGANDA'),
  (263, 'UKRAINE'),
  (264, 'UNITED ARAB EMIRATES'),
  (265, 'UNITED KINGDOM'),
  (266, 'UNITED STATES VIRGIN ISLANDS'),
  (267, 'UNITED STATES OF AMERICA'),
  (268, 'URUGUAY'),
  (269, 'UZBEKISTAN'),
  (270, 'VANUATU'),
  (271, 'VATICAN CITY (HOLYSEE)'),
  (272, 'VENEZUELA'),
  (273, 'VIETNAM'),
  (274, 'VIRGIN ISLANDS, BRITISH'),
  (275, 'VIRGIN ISLANDS, U.S.'),
  (276, 'WAKE ISLAND'),
  (277, 'WALLIS AND FUTUNA'),
  (278, 'WESTERN SAHARA'),
  (279, 'YEMEN'),
  (280, 'ZAMBIA'),
  (281, 'ZIMBABWE'),
  (282, 'COMBODIA'),
  (283, 'CONGO'),
  (284, 'IVORY COAST'),
  (285, 'WEST INDIES'),
  (286, 'BRITISH VIRGIN ISLANDS')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- ============================================================
-- >> from master__0008__lrs_other_rate_fix.sql
-- ============================================================
-- master__0008__lrs_other_rate_fix.sql
-- LRS remittance for OTHER purposes (paycode 49 -> 2025-Act code 1087): the TY2026-27
-- rate is 20% above the Rs.10 lakh threshold (TDSMAN/TaxGuru charts, verified 2026-07).
-- The ay-26 rows carried a stale 5.00. Guarded on the stale value so a deliberate
-- manual change is never clobbered; idempotent (re-run matches 0 rows).
UPDATE tdsrate SET rate = 20.00
WHERE ayid >= 26 AND paycode = 49 AND rate = 5.00;

-- ============================================================
-- >> from master__0009__newact_code_gaps.sql
-- ============================================================
-- master__0009__newact_code_gaps.sql
-- Follow-ups from the section-picker review:
-- 1. 24Q was missing 1032 â€” "Deduction of tax in case of specified senior citizens"
--    (old 194P, 393(1) [Table: Sl. No. 8(iii)]). Slab-based like salary -> no tdsrate rows.
-- 2. Stamp display newcodes on generic rows whose FVU fallback is deterministic anyway:
--    194LBA generic -> 1014 (interest default), bare 194I -> 1009, bare 194J -> 1027.
--    194C stays NULL on purpose (payee-dependent 1023/1024); 194LAA stays NULL (no
--    2025-Act code in Form 140 â€” property TDS is the 26QB channel).
-- Idempotent.

INSERT INTO tdsentriessection (paycode, section, name, "limit", formname, newsection, newcode)
SELECT 143, '194P', 'Deduction of tax in case of specified senior citizens (pension + interest via specified bank)', 0, '24Q', '393(1) [Table: Sl. No. 8(iii)]', '1032'
WHERE NOT EXISTS (SELECT 1 FROM tdsentriessection t WHERE t.formname='24Q' AND t.paycode=143);

UPDATE tdsentriessection SET newcode='1014' WHERE formname='26Q' AND paycode=53 AND newcode IS NULL; -- 194LBA generic
UPDATE tdsentriessection SET newcode='1009' WHERE formname='26Q' AND paycode=5  AND newcode IS NULL; -- bare 194I (rent default D(b))
UPDATE tdsentriessection SET newcode='1027' WHERE formname='26Q' AND paycode=8  AND newcode IS NULL; -- bare 194J (professional default)

-- ============================================================
-- >> from master__0010__rate_audit_fixes.sql
-- ============================================================
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

-- ============================================================
-- >> from master__0011__tcs_licensee_collectee_types.sql
-- ============================================================
-- master__0011__tcs_licensee_collectee_types.sql
-- TCS 206C(1C) licensee paycodes (35 mining/quarrying, 37 toll plaza, 38 car
-- parking) had ay-26 rate rows only for collectee type 1 (individual). The 2%
-- rate applies regardless of collectee type - licensees are frequently
-- companies/firms. Seed tsid 2 and 5 to match the shape of the other TCS rows.
-- Idempotent.
INSERT INTO tdsrate (ayid, tsid, paycode, rate, surch, "limit")
SELECT v.* FROM (VALUES
  (26, 2, 35, 2.00, 0.00, 0), (26, 5, 35, 2.00, 0.00, 0),
  (26, 2, 37, 2.00, 0.00, 0), (26, 5, 37, 2.00, 0.00, 0),
  (26, 2, 38, 2.00, 0.00, 0), (26, 5, 38, 2.00, 0.00, 0)
) AS v(ayid, tsid, paycode, rate, surch, "limit")
WHERE NOT EXISTS (
  SELECT 1 FROM tdsrate t WHERE t.ayid = v.ayid AND t.tsid = v.tsid AND t.paycode = v.paycode
);

