-- This script duplicates the nurse charting table, making the following changes:
--  "major" vital signs (frequently measured) -> pivoted_vital
--  "minor" vital signs (infrequently measured) -> pivoted_vital_other
DROP TABLE IF EXISTS repo_vital;
CREATE TABLE repo_vital AS -- create columns with only NUMERIC data
WITH vw0 AS (
	SELECT patientunitstayid,
		nursingchartoffset,
		nursingchartentryoffset,
		CASE
			WHEN nursingchartcelltypevallabel = 'Heart Rate'
			AND nursingchartcelltypevalname = 'Heart Rate'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS heartrate,
		CASE
			WHEN nursingchartcelltypevallabel = 'Respiratory Rate'
			AND nursingchartcelltypevalname = 'Respiratory Rate'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS resprate,
		CASE
			WHEN nursingchartcelltypevallabel = 'O2 Saturation'
			AND nursingchartcelltypevalname = 'O2 Saturation'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS spo2,
		CASE
			WHEN nursingchartcelltypevallabel = 'Non-Invasive BP'
			AND nursingchartcelltypevalname = 'Non-Invasive BP Systolic'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS nisbp,
		CASE
			WHEN nursingchartcelltypevallabel = 'Non-Invasive BP'
			AND nursingchartcelltypevalname = 'Non-Invasive BP Diastolic'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS nidbp,
		CASE
			WHEN nursingchartcelltypevallabel = 'Non-Invasive BP'
			AND nursingchartcelltypevalname = 'Non-Invasive BP Mean'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS nimbp,
		CASE
			WHEN nursingchartcelltypevallabel = 'Invasive BP'
			AND nursingchartcelltypevalname = 'Invasive BP Systolic'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS isbp,
		CASE
			WHEN nursingchartcelltypevallabel = 'Invasive BP'
			AND nursingchartcelltypevalname = 'Invasive BP Diastolic'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS idbp,
		CASE
			WHEN nursingchartcelltypevallabel = 'Invasive BP'
			AND nursingchartcelltypevalname = 'Invasive BP Mean'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC) -- other map fields
			WHEN nursingchartcelltypevallabel = 'MAP (mmHg)'
			AND nursingchartcelltypevalname = 'Value'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			WHEN nursingchartcelltypevallabel = 'Arterial Line MAP (mmHg)'
			AND nursingchartcelltypevalname = 'Value'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS imbp,
		CASE
			WHEN nursingchartcelltypevallabel = 'Temperature'
			AND nursingchartcelltypevalname = 'Temperature (C)'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS temperature,
		CASE
			WHEN nursingchartcelltypevallabel = 'Temperature'
			AND nursingchartcelltypevalname = 'Temperature Location' THEN nursingchartvalue
			ELSE NULL
		END AS temperature_site
	FROM icu.nursecharting -- speed up by only looking at a subset of charted data
	WHERE nursingchartcelltypecat IN (
			'Vital Signs',
			'Scores',
			'Other Vital Signs AND Infusions'
		)
)
SELECT patientunitstayid,
	nursingchartoffset AS chartoffset,
	nursingchartentryoffset AS entryoffset,
	ROUND(
		AVG(
			CASE
				WHEN heartrate >= 25
				AND heartrate <= 225 THEN heartrate
				ELSE NULL
			END
		)
	) AS heartrate,
	ROUND(
		AVG(
			CASE
				WHEN resprate >= 0
				AND resprate <= 60 THEN resprate
				ELSE NULL
			END
		)
	) AS resprate,
	ROUND(
		AVG(
			CASE
				WHEN spo2 >= 0
				AND spo2 <= 100 THEN spo2
				ELSE NULL
			END
		)
	) AS spo2,
	ROUND(
		AVG(
			CASE
				WHEN nisbp >= 25
				AND nisbp <= 250 THEN nisbp
				ELSE NULL
			END
		)
	) AS nisbp,
	ROUND(
		AVG(
			CASE
				WHEN nidbp >= 1
				AND nidbp <= 200 THEN nidbp
				ELSE NULL
			END
		)
	) AS nidbp,
	ROUND(
		AVG(
			CASE
				WHEN nimbp >= 1
				AND nimbp <= 250 THEN nimbp
				ELSE NULL
			END
		)
	) AS nimbp,
	ROUND(
		AVG(
			CASE
				WHEN isbp >= 1
				AND isbp <= 300 THEN isbp
				ELSE NULL
			END
		)
	) AS isbp,
	ROUND(
		AVG(
			CASE
				WHEN idbp >= 1
				AND idbp <= 200 THEN idbp
				ELSE NULL
			END
		)
	) AS idbp,
	ROUND(
		AVG(
			CASE
				WHEN imbp >= 1
				AND imbp <= 250 THEN imbp
				ELSE NULL
			END
		)
	) AS imbp,
	ROUND(
		AVG(
			CASE
				WHEN temperature >= 25
				AND temperature <= 46 THEN temperature
				ELSE NULL
			END
		),
		2
	) AS temperature,
	MAX(temperature_site) AS temperature_site
FROM vw0
WHERE heartrate IS NOT NULL
	OR resprate IS NOT NULL
	OR spo2 IS NOT NULL
	OR nisbp IS NOT NULL
	OR nidbp IS NOT NULL
	OR nimbp IS NOT NULL
	OR isbp IS NOT NULL
	OR idbp IS NOT NULL
	OR imbp IS NOT NULL
	OR temperature IS NOT NULL
	OR temperature_site IS NOT NULL
GROUP BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset
ORDER BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset;