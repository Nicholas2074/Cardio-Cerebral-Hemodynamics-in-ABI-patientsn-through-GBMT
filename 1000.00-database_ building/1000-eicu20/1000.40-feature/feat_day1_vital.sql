DROP TABLE IF EXISTS feat_day1_vital;
CREATE TABLE feat_day1_vital AS
-- //ANCHOR - heartrate
WITH heartrate AS (
	WITH t0 AS (
		SELECT tt.patientunitstayid,
			tt.chartoffset,
			tt.heartrate
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.heartrate > 0
	)
	SELECT patientunitstayid,
		ROUND(AVG(heartrate)) AS heartrate_avg,
		ROUND((STDDEV_SAMP(heartrate) / AVG(heartrate) * 100), 2) AS heartrate_cv -- if only 1 value in group, null will be returned
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY patientunitstayid
),
-- //ANCHOR - resprate
resprate AS (
	WITH t0 AS (
		SELECT tt.patientunitstayid,
			tt.chartoffset,
			tt.resprate
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.resprate > 0
	)
	SELECT patientunitstayid,
		ROUND(AVG(resprate)) AS resprate_avg,
		ROUND((STDDEV_SAMP(resprate) / AVG(resprate) * 100), 2) AS resprate_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY patientunitstayid
),
-- //ANCHOR - spo2
spo2 AS (
	WITH t0 AS (
		SELECT tt.patientunitstayid,
			tt.chartoffset,
			tt.spo2
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.spo2 > 0
	)
	SELECT patientunitstayid,
		ROUND(AVG(spo2)) AS spo2_avg,
		ROUND((STDDEV_SAMP(spo2) / AVG(spo2) * 100), 2) AS spo2_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY patientunitstayid
),
-- //ANCHOR - nibp
nibp AS (
	WITH t0 AS (
		SELECT DISTINCT tt.patientunitstayid,
			tt.chartoffset,
			tt.nisbp,
			tt.nidbp,
			CASE
				WHEN tt.nimbp IS NULL THEN ((tt.nisbp + tt.nidbp * 2) / 3)
				WHEN tt.nimbp IS NOT NULL THEN tt.nimbp
			END AS nimbp
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
	)
	SELECT patientunitstayid,
		ROUND(AVG(nisbp)) AS nisbp_avg,
		ROUND(AVG(nidbp)) AS nidbp_avg,
		ROUND(AVG(nimbp)) AS nimbp_avg,
		ROUND((STDDEV_SAMP(nisbp) / AVG(nisbp) * 100), 2) AS nisbp_cv,
		ROUND((STDDEV_SAMP(nidbp) / AVG(nidbp) * 100), 2) AS nidbp_cv,
		ROUND((STDDEV_SAMP(nimbp) / AVG(nimbp) * 100), 2) AS nimbp_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY patientunitstayid
),
-- //ANCHOR - ibp
ibp AS (
	WITH t0 AS (
		SELECT DISTINCT tt.patientunitstayid,
			tt.chartoffset,
			tt.isbp,
			tt.idbp,
			CASE
				WHEN tt.imbp IS NULL THEN ((tt.isbp + tt.idbp * 2) / 3)
				WHEN tt.imbp IS NOT NULL THEN tt.imbp
			END AS imbp
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
	)
	SELECT patientunitstayid,
		ROUND(AVG(isbp)) AS isbp_avg,
		ROUND(AVG(idbp)) AS idbp_avg,
		ROUND(AVG(imbp)) AS imbp_avg,
		ROUND((STDDEV_SAMP(isbp) / AVG(isbp) * 100), 2) AS isbp_cv,
		ROUND((STDDEV_SAMP(idbp) / AVG(idbp) * 100), 2) AS idbp_cv,
		ROUND((STDDEV_SAMP(imbp) / AVG(imbp) * 100), 2) AS imbp_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY patientunitstayid
),
-- //ANCHOR - temperature
temperature AS (
	WITH t0 AS (
		SELECT tt.patientunitstayid,
			tt.chartoffset,
			tt.temperature
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.temperature > 0
	)
	SELECT patientunitstayid,
		ROUND(AVG(temperature), 2) AS temperature_avg,
		ROUND(
			(STDDEV_SAMP(temperature) / AVG(temperature) * 100),
			2
		) AS temperature_cv
	FROM t0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY patientunitstayid
)
SELECT pt.patientunitstayid,
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
FROM icu.patient pt
	LEFT JOIN heartrate t1 ON pt.patientunitstayid = t1.patientunitstayid
	LEFT JOIN resprate t2 ON pt.patientunitstayid = t2.patientunitstayid
	LEFT JOIN spo2 t3 ON pt.patientunitstayid = t3.patientunitstayid
	LEFT JOIN nibp t4 ON pt.patientunitstayid = t4.patientunitstayid
	LEFT JOIN ibp t5 ON pt.patientunitstayid = t5.patientunitstayid
	LEFT JOIN temperature t6 ON pt.patientunitstayid = t6.patientunitstayid
ORDER BY pt.patientunitstayid;