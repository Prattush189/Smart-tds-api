-- year__0005__lc3_paycode_relink.sql
-- master__0010 moved 27Q section 194LC3 from the shared paycode 99 (collision with
-- 26Q 194E) to its own paycode 139. Relink any year-DB TDS entries saved under the
-- old paycode. 26Q 194E entries (also section=99 but formtype 26Q) are untouched.
-- Idempotent.
UPDATE tdsentry SET section = 139 WHERE section = 99 AND formtype = '27Q';
