-- //STUB - unionid_0
DROP MATERIALIZED VIEW IF EXISTS unionid_0;
CREATE MATERIALIZED VIEW unionid_0 AS
SELECT patientunitstayid
FROM public.tbiid_0
UNION
SELECT patientunitstayid
FROM public.sahid_0
UNION
SELECT patientunitstayid
FROM public.ichid_0;