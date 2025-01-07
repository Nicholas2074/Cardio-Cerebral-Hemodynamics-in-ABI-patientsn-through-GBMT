DROP TABLE IF EXISTS repo_cardiac;
CREATE TABLE repo_cardiac AS -- remove duplicate labs if they exist at the same time
WITH vw0 AS (
	SELECT patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	FROM icu.lab
	WHERE labname in (
		'CPK-MB', -- labtypeid = 1
		'CPK-MB INDEX', -- labtypeid = 1
		'CPK', -- labtypeid = 1
		'troponin - I', -- labtypeid = 1
		'troponin - T', -- labtypeid = 1
		'BNP' -- labtypeid = 4
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
			lab.labname = 'CPK-MB'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'CPK-MB INDEX'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'CPK'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'troponin - I'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'troponin - T'
			AND lab.labresult > 0
		)
		OR (
			lab.labname = 'BNP'
			AND lab.labresult > 0
		)
)
SELECT patientunitstayid,
	labresultoffset AS chartoffset,
	MAX(
		CASE
			WHEN labname = 'CPK-MB' THEN labresult
			ELSE NULL
		END
	) AS cpk_mb,
	MAX(
		CASE
			WHEN labname = 'CPK-MB INDEX' THEN labresult
			ELSE NULL
		END
	) AS cpk_mb_index,
	MAX(
		CASE
			WHEN labname = 'CPK' THEN labresult
			ELSE NULL
		END
	) AS cpk,
	MAX(
		CASE
			WHEN labname = 'troponin - I' THEN labresult
			ELSE NULL
		END
	) AS ctni,
	MAX(
		CASE
			WHEN labname = 'troponin - T' THEN labresult
			ELSE NULL
		END
	) AS ctnt,
	MAX(
		CASE
			WHEN labname = 'BNP' THEN labresult
			ELSE NULL
		END
	) AS bnp
FROM vw1
WHERE rn = 1
GROUP BY patientunitstayid,
	labresultoffset
ORDER BY patientunitstayid,
	labresultoffset;