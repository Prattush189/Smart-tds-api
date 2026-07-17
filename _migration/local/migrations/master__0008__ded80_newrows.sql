-- master__0008__ded80_newrows.sql
-- Salary-forms audit (2026-07-16): the Chapter VI-A deduction master (tdsded80)
-- had no rows for several live sections, so FrmIncomeAndTax could not represent:
--   80CCD(1B)  extra NPS self-contribution, cap 50,000 (old regime, OUTSIDE the
--              80CCE 1.5L cap - the distinct dedsec keeps it out of the app's
--              80C group set {80C,80CCC,80CCD,80CCF})
--   80CCD(2)   EMPLOYER NPS contribution - deductible in BOTH regimes (the only
--              mainstream new-regime deduction; 14% of basic+DA ceiling)
--   80TTB      senior-citizen deposit interest, cap 50,000 (old regime)
--   80CCH      Agniveer Corpus Fund contribution (both regimes)
-- The app's new-regime computation now allows exactly {80CCD(2), 80CCH}.
-- Idempotent (keyed on dedsec).

INSERT INTO tdsded80 (ded80id, dedsec, ded80name, dedtype, section, short, ind, sortid, ayid, ayid2)
SELECT v.* FROM (VALUES
  (16, '80CCD(1B)', 'NPS Contribution - Additional (Self, max 50,000)', 'CAP', '80CCD(1B)', '80CCD1B', true, 16, 0, 0),
  (17, '80CCD(2)',  'NPS Contribution by Employer (allowed in New Regime)', 'CAP', '80CCD(2)', '80CCD2', true, 17, 0, 0),
  (18, '80TTB',     'Interest on Deposits - Senior Citizen (max 50,000)', 'CAP', '80TTB', '80TTB', true, 18, 0, 0),
  (19, '80CCH',     'Agniveer Corpus Fund Contribution (allowed in New Regime)', 'CAP', '80CCH', '80CCH', true, 19, 0, 0)
) AS v(ded80id, dedsec, ded80name, dedtype, section, short, ind, sortid, ayid, ayid2)
WHERE NOT EXISTS (SELECT 1 FROM tdsded80 t WHERE t.dedsec = v.dedsec);
