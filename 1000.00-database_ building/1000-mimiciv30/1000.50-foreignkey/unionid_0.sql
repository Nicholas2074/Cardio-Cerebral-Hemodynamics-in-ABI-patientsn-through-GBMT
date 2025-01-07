-- //STUB - unionid_0
DROP MATERIALIZED VIEW IF EXISTS unionid_0;
CREATE MATERIALIZED VIEW unionid_0 AS
SELECT subject_id,
	hadm_id,
	stay_id,
	intime
FROM public.tbiid_0
UNION
SELECT subject_id,
	hadm_id,
	stay_id,
	intime
FROM public.sahid_0
UNION
SELECT subject_id,
	hadm_id,
	stay_id,
	intime
FROM public.ichid_0;