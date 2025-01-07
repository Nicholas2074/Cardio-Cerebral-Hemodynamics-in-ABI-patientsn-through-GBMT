DROP TABLE IF EXISTS repo_lipid;
CREATE TABLE repo_lipid AS -- remove duplicate labs if they exist at the same time
WITH vw0 AS (
	SELECT patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	FROM icu.lab
	WHERE labname in (
			'triglycerides', -- mg/dL
			'total cholesterol',
			'HDL',
			'LDL'
		) -- 1 for chemistry, 2 for drug level, 3 for hemo, 4 for misc, 5 for non-mapped, 6 for sensitive, 7 for ABG lab
	GROUP BY patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	HAVING COUNT(DISTINCT labresult) <= 1
),
-- get the last lab to be revised
vw1 AS (
	SELECT lab.patientunitstayid,
		lab.labname,
		lab.labresultoffset,
		lab.labresultrevisedoffset,
		lab.labresult,
		ROW_NUMBER() OVER (
			PARTITION BY lab.patientunitstayid,
			lab.labname,
			lab.labresultoffset
			ORDER BY lab.labresultrevisedoffset DESC
		) AS rn
	FROM icu.lab
		INNER JOIN vw0 ON lab.patientunitstayid = vw0.patientunitstayid
		AND lab.labname = vw0.labname
		AND lab.labresultoffset = vw0.labresultoffset
		AND lab.labresultrevisedoffset = vw0.labresultrevisedoffset -- only valid lab values
	WHERE (
			lab.labname = 'triglycerides'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'total cholesterol'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'HDL'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'LDL'
			AND lab.labresult > 0
		)
)
SELECT patientunitstayid,
	labresultoffset AS chartoffset,
	MAX(
		CASE
			WHEN labname = 'triglycerides' THEN labresult
			ELSE NULL
		END
	) AS tg,
	MAX(
		CASE
			WHEN labname = 'total cholesterol' THEN labresult
			ELSE NULL
		END
	) AS tcho,
	MAX(
		CASE
			WHEN labname = 'HDL' THEN labresult
			ELSE NULL
		END
	) AS hdl,
	MAX(
		CASE
			WHEN labname = 'LDL' THEN labresult
			ELSE NULL
		END
	) AS ldl
FROM vw1
WHERE rn = 1
GROUP BY patientunitstayid,
	labresultoffset
ORDER BY patientunitstayid,
	labresultoffset;