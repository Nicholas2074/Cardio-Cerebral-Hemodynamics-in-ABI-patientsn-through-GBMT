DROP TABLE IF EXISTS feat_day1_vital;
CREATE TABLE feat_day1_vital AS
-- //ANCHOR - heartrate
WITH heartrate AS (
	WITH t0 AS (
		SELECT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.heartrate
		FROM icu.icustays pt
			INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
		WHERE tt.heartrate > 0
	)
	SELECT stay_id,
		ROUND(AVG(heartrate)) AS heartrate_avg,
		ROUND((STDDEV_SAMP(heartrate) / AVG(heartrate) * 100), 2) AS heartrate_cv -- if only 1 value in group, null will be returned
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
),
-- //ANCHOR - resprate
resprate AS (
	WITH t0 AS (
		SELECT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.resprate
		FROM icu.icustays pt
			INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
		WHERE tt.resprate > 0
	)
	SELECT stay_id,
		ROUND(AVG(resprate)) AS resprate_avg,
		ROUND((STDDEV_SAMP(resprate) / AVG(resprate) * 100), 2) AS resprate_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
),
-- //ANCHOR - spo2
spo2 AS (
	WITH t0 AS (
		SELECT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.spo2
		FROM icu.icustays pt
			INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
		WHERE tt.spo2 > 0
	)
	SELECT stay_id,
		ROUND(AVG(spo2)) AS spo2_avg,
		ROUND((STDDEV_SAMP(spo2) / AVG(spo2) * 100), 2) AS spo2_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
),
-- //ANCHOR - nibp
nibp AS (
	WITH t0 AS (
		SELECT DISTINCT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.nisbp,
			tt.nidbp,
			CASE
				WHEN tt.nimbp IS NULL THEN ((tt.nisbp + tt.nidbp * 2) / 3)
				WHEN tt.nimbp IS NOT NULL THEN tt.nimbp
			END AS nimbp
		FROM icu.icustays pt
			INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
	)
	SELECT stay_id,
		ROUND(AVG(nisbp)) AS nisbp_avg,
		ROUND(AVG(nidbp)) AS nidbp_avg,
		ROUND(AVG(nimbp)) AS nimbp_avg,
		ROUND((STDDEV_SAMP(nisbp) / AVG(nisbp) * 100), 2) AS nisbp_cv,
		ROUND((STDDEV_SAMP(nidbp) / AVG(nidbp) * 100), 2) AS nidbp_cv,
		ROUND((STDDEV_SAMP(nimbp) / AVG(nimbp) * 100), 2) AS nimbp_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
),
-- //ANCHOR - ibp
ibp AS (
	WITH t0 AS (
		SELECT DISTINCT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.isbp,
			tt.idbp,
			CASE
				WHEN tt.imbp IS NULL THEN ((tt.isbp + tt.idbp * 2) / 3)
				WHEN tt.imbp IS NOT NULL THEN tt.imbp
			END AS imbp
		FROM icu.icustays pt
			INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
	)
	SELECT stay_id,
		ROUND(AVG(isbp)) AS isbp_avg,
		ROUND(AVG(idbp)) AS idbp_avg,
		ROUND(AVG(imbp)) AS imbp_avg,
		ROUND((STDDEV_SAMP(isbp) / AVG(isbp) * 100), 2) AS isbp_cv,
		ROUND((STDDEV_SAMP(idbp) / AVG(idbp) * 100), 2) AS idbp_cv,
		ROUND((STDDEV_SAMP(imbp) / AVG(imbp) * 100), 2) AS imbp_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
),
-- //ANCHOR - temperature
temperature AS (
	WITH t0 AS (
		SELECT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.temperature
		FROM icu.icustays pt
			INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
		WHERE tt.temperature > 0
	)
	SELECT stay_id,
		ROUND(AVG(temperature), 2) AS temperature_avg,
		ROUND(
			(STDDEV_SAMP(temperature) / AVG(temperature) * 100),
			2
		) AS temperature_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
)
SELECT pt.stay_id,
	t1.heartrate_cv,
	t2.resprate_cv,
	t3.spo2_cv,
	t4.nisbp_cv,
	t4.nidbp_cv,
	t4.nimbp_cv,
	t5.isbp_cv,
	t5.idbp_cv,
	t5.imbp_cv,
	t6.temperature_cv,
	t1.heartrate_avg,
	t2.resprate_avg,
	t3.spo2_avg,
	t4.nisbp_avg,
	t4.nidbp_avg,
	t4.nimbp_avg,
	t5.isbp_avg,
	t5.idbp_avg,
	t5.imbp_avg,
	t6.temperature_avg
FROM icu.icustays pt
	LEFT JOIN heartrate t1 ON pt.stay_id = t1.stay_id
	LEFT JOIN resprate t2 ON pt.stay_id = t2.stay_id
	LEFT JOIN spo2 t3 ON pt.stay_id = t3.stay_id
	LEFT JOIN nibp t4 ON pt.stay_id = t4.stay_id
	LEFT JOIN ibp t5 ON pt.stay_id = t5.stay_id
	LEFT JOIN temperature t6 ON pt.stay_id = t6.stay_id
ORDER BY pt.stay_id;