DROP TABLE IF EXISTS repo_chemistry;
CREATE TABLE repo_chemistry AS -- remove duplicate labs if they exist at the same time
WITH vw0 AS (
	SELECT patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	FROM icu.lab
	WHERE labname in (
		'bedside glucose', -- mg/dL
		'glucose', --mg/dL
		'lactate', -- only labtypeid = 1
		-- lose blood gas lactate
		'ALT (SGPT)',
		'AST (SGOT)',
		'alkaline phos.' -- ALP, alkaline phosphatase
		'total bilirubin', -- lose direct bilirubin and indirect bilirubin
		-- '-bands', -- liver enzymes(source code seems wrong)
		'albumin',
		'total protein',
		'creatinine',
		'BUN', -- blood urea nitrogen
		'anion gap', -- only labtypeid = 1
		'bicarbonate', -- HCO3, labtypeid = 1
		'sodium', -- only labtypeid = 1
		'potassium', -- only labtypeid = 1
		'calcium', -- only labtypeid = 1
		'chloride', -- only labtypeid = 1
		'magnesium' -- only labtypeid = 1
		-- lose phosphorus
		)
		-- 1 for chemistry, 2 for drug level, 3 for hemo, 4 for misc, 5 for non-mapped, 6 for sensitive, 7 for ABG lab
	GROUP BY patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	HAVING COUNT(DISTINCT labresult) <= 1
), -- get the last lab to be revised
vw1 AS (
	SELECT tt.patientunitstayid,
		tt.labname,
		tt.labresultoffset,
		tt.labresultrevisedoffset,
		tt.labresult,
		ROW_NUMBER() OVER (
			PARTITION BY tt.patientunitstayid,
			tt.labname,
			tt.labresultoffset
			ORDER BY tt.labresultrevisedoffset DESC
		) AS rn
	FROM icu.lab tt
		INNER JOIN vw0 ON tt.patientunitstayid = vw0.patientunitstayid
		AND tt.labname = vw0.labname
		AND tt.labresultoffset = vw0.labresultoffset
		AND tt.labresultrevisedoffset = vw0.labresultrevisedoffset -- only valid lab values
	WHERE	(
			tt.labname IN ('bedside glucose', 'glucose')
			AND tt.labresult >= 25
		)
		OR (
			tt.labname = 'lactate'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'ALT (SGPT)'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'AST (SGOT)'
			AND tt.labresult > 0
		)
		-- OR (
		-- 	tt.labname = '-bands'
		-- 	AND tt.labresult > 0
		-- )
		OR (
			tt.labname = 'alkaline phos.'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'total bilirubin'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'albumin'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'total protein'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'creatinine'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'BUN'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'anion gap'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'bicarbonate'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'sodium'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'potassium'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'calcium'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'chloride'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'magnesium'
			AND tt.labresult > 0
		)
)
SELECT patientunitstayid,
	labresultoffset AS chartoffset,
	MAX(
		CASE
			WHEN labname IN ('bedside glucose', 'glucose') THEN labresult
			ELSE NULL
		END
	) AS glucose,
	MAX(
		CASE
			WHEN labname = 'lactate' THEN labresult
			ELSE NULL
		END
	) AS lac,
	MAX(
		CASE
			WHEN labname = 'ALT (SGPT)' THEN labresult
			ELSE NULL
		END
	) AS alt,
	MAX(
		CASE
			WHEN labname = 'AST (SGOT)' THEN labresult
			ELSE NULL
		END
	) AS ast,
	MAX(
		CASE
			WHEN labname = 'alkaline phos.' THEN labresult
			ELSE NULL
		END
	) AS alp,
	MAX(
		CASE
			WHEN labname = 'total bilirubin' THEN labresult
			ELSE NULL
		END
	) AS tbil,
	-- MAX(
	-- 	CASE
	-- 		WHEN labname = '-bands' THEN labresult
	-- 		ELSE NULL
	-- 	END
	-- ) AS bands,
	MAX(
		CASE
			WHEN labname = 'albumin' THEN labresult
			ELSE NULL
		END
	) AS albumin,
	MAX(
		CASE
			WHEN labname = 'total protein' THEN labresult
			ELSE NULL
		END
	) AS total_protein,
	MAX(
		CASE
			WHEN labname = 'creatinine' THEN labresult
			ELSE NULL
		END
	) AS creatinine,
	MAX(
		CASE
			WHEN labname = 'BUN' THEN labresult
			ELSE NULL
		END
	) AS bun,
	MAX(
		CASE
			WHEN labname = 'anion gap' THEN labresult
			ELSE NULL
		END
	) AS aniongap,
	MAX(
		CASE
			WHEN labname = 'bicarbonate' THEN labresult
			ELSE NULL
		END
	) AS bicarbonate,
	MAX(
		CASE
			WHEN labname = 'sodium' THEN labresult
			ELSE NULL
		END
	) AS sodium,
	MAX(
		CASE
			WHEN labname = 'potassium' THEN labresult
			ELSE NULL
		END
	) AS potassium,
	MAX(
		CASE
			WHEN labname = 'calcium' THEN labresult
			ELSE NULL
		END
	) AS calcium,
	MAX(
		CASE
			WHEN labname = 'chloride' THEN labresult
			ELSE NULL
		END
	) AS chloride,
	MAX(
		CASE
			WHEN labname = 'magnesium' THEN labresult
			ELSE NULL
		END
	) AS magnesium
FROM vw1
WHERE rn = 1
GROUP BY patientunitstayid,
	labresultoffset
ORDER BY patientunitstayid,
	labresultoffset;