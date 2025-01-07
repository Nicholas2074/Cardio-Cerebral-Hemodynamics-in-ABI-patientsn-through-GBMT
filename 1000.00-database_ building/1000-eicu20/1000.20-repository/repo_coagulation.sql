DROP TABLE IF EXISTS repo_coagulation;
CREATE TABLE repo_coagulation AS
WITH vw0 AS (
	SELECT patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	FROM icu.lab
	WHERE labname in (
		'PT - INR',
		'PT',
		'PTT',
		-- lose thrombin
		'fibrinogen'
		-- lose dimer
		)
		-- 1 for chemistry, 2 for drug level, 3 for hemo, 4 for misc, 5 for non-mapped, 6 for sensitive, 7 for ABG lab
	GROUP BY patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	HAVING COUNT(DISTINCT labresult) <= 1
), -- get the last lab to be revised
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
			lab.labname = 'PT - INR'
			AND lab.labresult >= 0.5
			AND lab.labresult <= 15
		)
		OR (
			lab.labname = 'PT'
			AND lab.labresult >= 0.5
			AND lab.labresult <= 15
		)
		OR (
			lab.labname = 'PTT'
			AND lab.labresult > 0
			AND lab.labresult <= 500
		)
		OR (
			lab.labname = 'fibrinogen'
			AND lab.labresult > 0
		)
)
SELECT patientunitstayid,
	labresultoffset AS chartoffset,
	MAX(
		CASE
			WHEN labname = 'PT -INR' THEN labresult
			ELSE NULL
		END
	) AS inr,
	MAX(
		CASE
			WHEN labname = 'PT' THEN labresult
			ELSE NULL
		END
	) AS pt,
	MAX(
		CASE
			WHEN labname = 'PTT' THEN labresult
			ELSE NULL
		END
	) AS ptt,
	MAX(
		CASE
			WHEN labname = 'fibrinogen' THEN labresult
			ELSE NULL
		END
	) AS fibrinogen
FROM vw1
WHERE rn = 1
GROUP BY patientunitstayid,
	labresultoffset
ORDER BY patientunitstayid,
	labresultoffset;