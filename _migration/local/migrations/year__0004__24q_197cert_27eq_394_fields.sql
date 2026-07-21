-- year__0004__24q_197cert_27eq_394_fields.sql
-- New deductee/collectee-detail capture for the 2025-Act FVU generator (eTdsR).
--
--  • 24Q (Form 138) Annexure-6 flag 'A': a salaried employee holding a lower-
--    deduction certificate under section 395(1) (old section 197). Stored per
--    employee-per-year on the salary computation; drives deductee fields 32 ('A')
--    and 33 (15-char certificate number).
--
--  • 27EQ (Form 143) section 394(5) chain — collectee-detail fields 34/35/36
--    (S/T/U): whether the collectee's payment is ALSO liable to TDS (Y/N), and
--    when Y the challan number + date of payment. Only meaningful for reason-'F'
--    (LRS / tour-package) collection codes 1086-1089.
--
-- Idempotent (ADD COLUMN IF NOT EXISTS) — safe to re-run. Widths mirror the
-- existing deductee-side certificate (tdsentry.certno varchar(26), year__0003).

ALTER TABLE tdscompincome ADD COLUMN IF NOT EXISTS cert197 varchar(26);

ALTER TABLE tdsentry ADD COLUMN IF NOT EXISTS liable394  varchar(1);
ALTER TABLE tdsentry ADD COLUMN IF NOT EXISTS challan394 varchar(10);
ALTER TABLE tdsentry ADD COLUMN IF NOT EXISTS datepay394 varchar(10);
