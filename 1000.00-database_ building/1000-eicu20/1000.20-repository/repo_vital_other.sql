-- This script duplicates the nurse charting table, making the following changes:
--  "major" vital signs (frequently measured) -> pivoted_vital
--  "minor" vital signs (infrequently measured) -> pivoted_vital_other
DROP TABLE IF EXISTS repo_vital_other;
CREATE TABLE repo_vital_other AS -- create columns with only numeric data
WITH vw1 AS (
	SELECT patientunitstayid,
		nursingchartoffset,
		nursingchartentryoffset,
		-- pivot data - choose column names for consistency with vitalperiodic
		CASE
			WHEN nursingchartcelltypevallabel = 'PA'
			AND nursingchartcelltypevalname = 'PA Systolic' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS pasystolic,
		CASE
			WHEN nursingchartcelltypevallabel = 'PA'
			AND nursingchartcelltypevalname = 'PA Diastolic' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS padiastolic,
		CASE
			WHEN nursingchartcelltypevallabel = 'PA'
			AND nursingchartcelltypevalname = 'PA Mean' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS pamean,
		CASE
			WHEN nursingchartcelltypevallabel = 'SV'
			AND nursingchartcelltypevalname = 'SV' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS sv,
		CASE
			WHEN nursingchartcelltypevallabel = 'CO'
			AND nursingchartcelltypevalname = 'CO' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS co,
		CASE
			WHEN nursingchartcelltypevallabel = 'SVR'
			AND nursingchartcelltypevalname = 'SVR' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS svr,
		CASE
			WHEN nursingchartcelltypevallabel = 'ICP'
			AND nursingchartcelltypevalname = 'ICP' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS icp,
		CASE
			WHEN nursingchartcelltypevallabel = 'CI'
			AND nursingchartcelltypevalname = 'CI' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS ci,
		CASE
			WHEN nursingchartcelltypevallabel = 'SVRI'
			AND nursingchartcelltypevalname = 'SVRI' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS svri,
		CASE
			WHEN nursingchartcelltypevallabel = 'CPP'
			AND nursingchartcelltypevalname = 'CPP' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS cpp,
		CASE
			WHEN nursingchartcelltypevallabel = 'SVO2'
			AND nursingchartcelltypevalname = 'SVO2' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS svo2,
		CASE
			WHEN nursingchartcelltypevallabel = 'PAOP'
			AND nursingchartcelltypevalname = 'PAOP' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS paop,
		CASE
			WHEN nursingchartcelltypevallabel = 'PVR'
			AND nursingchartcelltypevalname = 'PVR' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS pvr,
		CASE
			WHEN nursingchartcelltypevallabel = 'PVRI'
			AND nursingchartcelltypevalname = 'PVRI' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS pvri,
		CASE
			WHEN nursingchartcelltypevallabel = 'IAP'
			AND nursingchartcelltypevalname = 'IAP' -- verify it's numeric
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS iap -- intra-abdominal pressure
	FROM icu.nursecharting -- speed up by only looking at a subset of charted data
	WHERE nursingchartcelltypecat = 'Vital Signs'
)
SELECT patientunitstayid,
	nursingchartoffset AS chartoffset,
	nursingchartentryoffset AS entryoffset,
	AVG(
		CASE
			WHEN pasystolic >= 0
			AND pasystolic <= 1000 THEN pasystolic
			ELSE NULL
		END
	) AS pasystolic,
	AVG(
		CASE
			WHEN padiastolic >= 0
			AND padiastolic <= 1000 THEN padiastolic
			ELSE NULL
		END
	) AS padiastolic,
	AVG(
		CASE
			WHEN pamean >= 0
			AND pamean <= 1000 THEN pamean
			ELSE NULL
		END
	) AS pamean,
	AVG(
		CASE
			WHEN sv >= 0
			AND sv <= 1000 THEN sv
			ELSE NULL
		END
	) AS sv,
	AVG(
		CASE
			WHEN co >= 0
			AND co <= 1000 THEN co
			ELSE NULL
		END
	) AS co,
	AVG(
		CASE
			WHEN svr >= 0
			AND svr <= 1000 THEN svr
			ELSE NULL
		END
	) AS svr,
	AVG(
		CASE
			WHEN icp > 0
			AND icp < 100 THEN icp
			ELSE NULL
		END
	) AS icp,
	AVG(
		CASE
			WHEN ci >= 0
			AND ci <= 1000 THEN ci
			ELSE NULL
		END
	) AS ci,
	AVG(
		CASE
			WHEN svri >= 0
			AND svri <= 1000 THEN svri
			ELSE NULL
		END
	) AS svri,
	AVG(
		CASE
			WHEN cpp >= 0
			AND cpp <= 1000 THEN cpp
			ELSE NULL
		END
	) AS cpp,
	AVG(
		CASE
			WHEN svo2 >= 0
			AND svo2 <= 1000 THEN svo2
			ELSE NULL
		END
	) AS svo2,
	AVG(
		CASE
			WHEN paop >= 0
			AND paop <= 1000 THEN paop
			ELSE NULL
		END
	) AS paop,
	AVG(
		CASE
			WHEN pvr >= 0
			AND pvr <= 1000 THEN pvr
			ELSE NULL
		END
	) AS pvr,
	AVG(
		CASE
			WHEN pvri >= 0
			AND pvri <= 1000 THEN pvri
			ELSE NULL
		END
	) AS pvri,
	AVG(
		CASE
			WHEN iap >= 0
			AND iap <= 1000 THEN iap
			ELSE NULL
		END
	) AS iap
FROM vw1
WHERE pasystolic IS NOT NULL
	OR padiastolic IS NOT NULL
	OR pamean IS NOT NULL
	OR sv IS NOT NULL
	OR co IS NOT NULL
	OR svr IS NOT NULL
	OR icp IS NOT NULL
	OR ci IS NOT NULL
	OR svri IS NOT NULL
	OR cpp IS NOT NULL
	OR svo2 IS NOT NULL
	OR paop IS NOT NULL
	OR pvr IS NOT NULL
	OR pvri IS NOT NULL
	OR iap IS NOT NULL
GROUP BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset
ORDER BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset;