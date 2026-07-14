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
