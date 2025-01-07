DROP TABLE IF EXISTS dmin_hr;
CREATE TABLE dmin_hr AS 
WITH nurse AS (
	SELECT DISTINCT tt.patientunitstayid,
		tt.chartoffset,
		tt.heartrate AS hr
	FROM icu.patient pt
		INNER JOIN public.repo_vital tt -- pivoted_vital is from nursecharting
		ON pt.patientunitstayid = tt.patientunitstayid
	WHERE tt.heartrate > 0
),
vital AS (
	SELECT DISTINCT tt.patientunitstayid,
		tt.observationoffset AS chartoffset,
		tt.heartrate AS hr
	FROM icu.patient pt
		INNER JOIN icu.vitalperiodic tt -- vitalperiodic is from bedside
		ON pt.patientunitstayid = tt.patientunitstayid
	WHERE tt.heartrate > 0
)
SELECT t1.patientunitstayid,
	t1.chartoffset,
	t1.hr
FROM nurse t1
UNION
SELECT t2.patientunitstayid,
	t2.chartoffset,
	t2.hr
FROM vital t2