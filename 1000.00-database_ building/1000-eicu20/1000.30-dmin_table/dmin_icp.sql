DROP TABLE IF EXISTS dmin_icp;
CREATE TABLE dmin_icp AS
WITH vw0 AS (
	WITH nurse AS (
		SELECT pt.patientunitstayid,
			tt.chartoffset,
			tt.icp
		FROM icu.patient pt
			INNER JOIN public.repo_vital_other tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.icp > 0
	),
	vital AS (
		SELECT pt.patientunitstayid,
			tt.observationoffset AS chartoffset,
			-- observationoffset: number of minutes from 
			-- unit admit time that the periodic value was entered
			tt.icp
		FROM icu.patient pt
			INNER JOIN icu.vitalperiodic tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.icp > 0
	)
	SELECT t1.patientunitstayid,
		t1.chartoffset,
		t1.icp
	FROM nurse t1
	UNION
	SELECT t2.patientunitstayid,
		t2.chartoffset,
		t2.icp
	FROM vital t2
)
SELECT patientunitstayid,
	chartoffset,
	ROUND(AVG(icp::NUMERIC)) AS icp
FROM vw0
GROUP BY patientunitstayid,
	chartoffset
ORDER BY patientunitstayid,
	chartoffset;