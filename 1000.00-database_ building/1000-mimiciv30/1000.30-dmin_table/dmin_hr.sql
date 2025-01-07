DROP TABLE IF EXISTS dmin_hr;
CREATE TABLE dmin_hr AS
SELECT DISTINCT tt.stay_id,
	CAST(
		ROUND(
			EXTRACT(
				EPOCH
				FROM (tt.charttime - pt.intime)
			) / 60
		) AS INTEGER
	) AS chartoffset,
	tt.heartrate AS hr
FROM icu.icustays pt
	INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id