DROP TABLE IF EXISTS dmin_bp;
CREATE TABLE dmin_bp AS 
-- //ANCHOR - ibp
WITH ibp AS (
	WITH nurse1 AS (
		SELECT DISTINCT pt.patientunitstayid,
			tt.chartoffset,
			tt.isbp,
			tt.idbp
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.isbp > 0
			AND tt.idbp > 0
	),
	vital1 AS (
		SELECT DISTINCT pt.patientunitstayid,
			tt.observationoffset AS chartoffset,
			tt.systemicsystolic AS isbp,
			tt.systemicdiastolic AS idbp
		FROM icu.patient pt
			INNER JOIN icu.vitalperiodic tt -- invasivebp
            -- Invasive blood pressure (systolic and diastolic)
			ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.systemicsystolic > 0
			AND tt.systemicdiastolic > 0
	)
	SELECT t1.patientunitstayid,
		t1.chartoffset,
		t1.isbp,
		t1.idbp
	FROM nurse1 t1
	UNION
	SELECT t2.patientunitstayid,
		t2.chartoffset,
		t2.isbp,
		t2.idbp
	FROM vital1 t2
),
-- //ANCHOR - nibp
nibp AS (
	WITH nurse2 AS (
		SELECT DISTINCT pt.patientunitstayid,
			tt.chartoffset,
			tt.nisbp,
			tt.nidbp
		FROM icu.patient pt
			INNER JOIN public.repo_vital tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.nisbp > 0
			AND tt.nidbp > 0
	),
	vital2 AS (
		SELECT DISTINCT pt.patientunitstayid,
			tt.observationoffset AS chartoffset,
			tt.noninvasivesystolic AS nisbp,
			tt.noninvasivediastolic AS nidbp
		FROM icu.patient pt
			INNER JOIN icu.vitalaperiodic tt -- noninvasivebp
            -- Non-invasive blood pressure
			ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.noninvasivesystolic > 0
			AND tt.noninvasivediastolic > 0
	)
	SELECT t3.patientunitstayid,
		t3.chartoffset,
		t3.nisbp,
		t3.nidbp
	FROM nurse2 t3
	UNION
	SELECT t4.patientunitstayid,
		t4.chartoffset,
		t4.nisbp,
		t4.nidbp
	FROM vital2 t4
)
SELECT t1.patientunitstayid,
	t1.chartoffset,
	ROUND(AVG(t1.isbp::NUMERIC)) AS isbp,
	ROUND(AVG(t1.idbp::NUMERIC)) AS idbp,
	ROUND(AVG(t2.nisbp::NUMERIC)) AS nisbp,
	ROUND(AVG(t2.nidbp::NUMERIC)) AS nidbp
FROM ibp t1
	FULL OUTER JOIN nibp t2 ON t1.patientunitstayid = t2.patientunitstayid
	AND t1.chartoffset = t2.chartoffset
GROUP BY t1.patientunitstayid,
	t1.chartoffset
ORDER BY t1.patientunitstayid,
	t1.chartoffset;