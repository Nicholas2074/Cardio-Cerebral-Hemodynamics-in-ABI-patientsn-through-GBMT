DROP TABLE IF EXISTS repo_gcs;
CREATE TABLE public.repo_gcs AS 
WITH vw1 AS (
	SELECT patientunitstayid,
		nursingchartoffset AS chartoffset,
		MIN(
			CASE
				WHEN nursingchartcelltypevallabel = 'Glasgow coma score'
				AND nursingchartcelltypevalname = 'GCS Total'
				AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
				AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS numeric)
				WHEN nursingchartcelltypevallabel = 'Score (Glasgow Coma Scale)'
				AND nursingchartcelltypevalname = 'Value'
				AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
				AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS numeric)
				ELSE NULL
			END
		) AS gcs,
		MIN(
			CASE
				WHEN nursingchartcelltypevallabel = 'Glasgow coma score'
				AND nursingchartcelltypevalname = 'Motor'
				AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
				AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS numeric)
				ELSE NULL
			END
		) AS gcsmotor,
		MIN(
			CASE
				WHEN nursingchartcelltypevallabel = 'Glasgow coma score'
				AND nursingchartcelltypevalname = 'Verbal'
				AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
				AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS numeric)
				ELSE NULL
			END
		) AS gcsverbal,
		MIN(
			CASE
				WHEN nursingchartcelltypevallabel = 'Glasgow coma score'
				AND nursingchartcelltypevalname = 'Eyes'
				AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
				AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS numeric)
				ELSE NULL
			END
		) AS gcseyes
	FROM icu.nursecharting -- speed up by only looking at a subset of charted data
	WHERE nursingchartcelltypecat IN (
			'Scores',
			'Other Vital Signs AND Infusions'
		)
	GROUP BY patientunitstayid,
		nursingchartoffset
) -- apply some preprocessing to fields
,
ncproc AS (
	SELECT patientunitstayid,
		chartoffset,
		CASE
			WHEN gcs > 2
			AND gcs < 16 THEN gcs
			ELSE NULL
		END AS gcs,
		gcsmotor,
		gcsverbal,
		gcseyes
	FROM vw1
)
SELECT DISTINCT patientunitstayid,
	chartoffset,
	gcs,
	gcsmotor,
	gcsverbal,
	gcseyes
FROM ncproc
WHERE gcs IS NOT NULL
	OR gcsmotor IS NOT NULL
	OR gcsverbal IS NOT NULL
	OR gcseyes IS NOT NULL
ORDER BY patientunitstayid,
	chartoffset;