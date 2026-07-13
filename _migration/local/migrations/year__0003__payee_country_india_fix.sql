-- year__0003__payee_country_india_fix.sql
-- Payee.country uses the SEQUENTIAL NSDL/Annexure-10 country scheme (India = 113),
-- but FrmPayee's dropdown was wired to the PAYER dial-style list and defaulted every
-- new payee to 91. Under the serial scheme 91 = GERMANY, so those defaulted rows
-- mislabel Indian payees. Recode them to 113.
--
-- Safe because 91 could only have arrived via that wrong default (a genuine German
-- payee could not be selected: the dial list the form showed has no Germany=91 row
-- either - Germany is 49 there). Idempotent (second run matches 0 rows).
UPDATE payee SET country = 113 WHERE country = 91;
