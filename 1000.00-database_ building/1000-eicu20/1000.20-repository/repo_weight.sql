DROP TABLE IF EXISTS repo_weight;
CREATE TABLE repo_weight AS
WITH htwt AS (
	SELECT patientunitstayid,
		hospitaladmitoffset AS chartoffset,
		admissionheight AS height,
		admissionweight AS weight,
		CASE
			-- CHECK weight vs. height are swapped
			WHEN admissionweight >= 100
			AND admissionheight > 25
			AND admissionheight <= 100
			AND abs(admissionheight - admissionweight) >= 20 THEN 'swap'
		END AS method
	FROM icu.patient
),
htwt_fixed AS (
	SELECT patientunitstayid,
		chartoffset,
		'admit' AS weight_type,
		CASE
			WHEN method = 'swap' THEN weight
			WHEN height <= 0.30 THEN NULL
			WHEN height <= 2.5 THEN height * 100
			WHEN height <= 10 THEN NULL
			WHEN height <= 25 THEN height * 10 -- CHECK weight in both columns
			WHEN height <= 100
			AND abs(height - weight) < 20 THEN NULL
			WHEN height > 250 THEN NULL
			ELSE height
		END AS height_fixed,
		CASE
			WHEN method = 'swap' THEN height
			WHEN weight <= 20 THEN NULL
			WHEN weight > 300 THEN NULL
			ELSE weight
		END AS weight_fixed
	FROM htwt
), -- extract weight from the charted data
wt1 AS (
	SELECT patientunitstayid,
		nursingchartoffset AS chartoffset, -- all of the below weights are measured in kg
		CASE
			WHEN nursingchartcelltypevallabel IN (
				'Admission Weight',
				'Admit weight'
			) THEN 'admit'
			ELSE 'daily'
		END AS weight_type,
		nursingchartvalue::NUMERIC AS weight
	FROM icu.nursecharting
	WHERE nursingchartcelltypecat = 'Other Vital Signs and Infusions'
		AND nursingchartcelltypevallabel IN (
			'Admission Weight',
			'Admit weight',
			'WEIGHT in Kg'
		)
		-- ensure that nursingchartvalue is numeric
		AND nursingchartvalue ~ '^([0-9]+\.?[0-9]*|\.[0-9]+)$'
		AND nursingchartoffset < 60 * 24
), -- weight from intake/output table
wt2 AS (
	SELECT patientunitstayid,
		intakeoutputoffset AS chartoffset,
		'daily' AS weight_type,
		MAX(
			CASE
				WHEN cellpath = 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (kg)' then cellvaluenumeric
				else NULL
			END
		) AS weight_kg, -- there are ~300 extra (lb) measurements compared to kg, so we include both
		MAX(
			CASE
				WHEN cellpath = 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (lb)' then cellvaluenumeric * 0.453592
				else NULL
			END
		) AS weight_kg2
	FROM icu.intakeoutput
	WHERE CELLPATH IN (
			'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (kg)',
			'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (lb)'
		)
		AND INTAKEOUTPUTOFFSET < 60 * 24
	GROUP BY patientunitstayid,
		intakeoutputoffset
), -- weight from infusiondrug
wt3 AS (
	SELECT patientunitstayid,
		infusionoffset AS chartoffset,
		'daily' AS weight_type,
		patientweight::NUMERIC AS weight
	FROM icu.infusiondrug
	WHERE patientweight ~ '^([0-9]+\.?[0-9]*|\.[0-9]+)$'
		AND infusionoffset < 60 * 24
) -- combine together all weights
SELECT patientunitstayid,
	chartoffset,
	'patient' AS source_table,
	weight_type,
	ROUND(weight_fixed, 2) AS weight
FROM htwt_fixed
WHERE weight_fixed IS NOT NULL
UNION ALL
SELECT patientunitstayid,
	chartoffset,
	'nursecharting' AS source_table,
	weight_type,
	ROUND(weight, 2) AS weight
FROM wt1
WHERE weight IS NOT NULL
UNION ALL
SELECT patientunitstayid,
	chartoffset,
	'intakeoutput' AS source_table,
	weight_type,
	ROUND(COALESCE(weight_kg, weight_kg2), 2) AS weight
FROM wt2
WHERE weight_kg IS NOT NULL
	OR weight_kg2 IS NOT NULL
UNION ALL
SELECT patientunitstayid,
	chartoffset,
	'infusiondrug' AS source_table,
	weight_type,
	ROUND(weight, 2) AS weight
FROM wt3
WHERE weight IS NOT NULL
ORDER BY 1,
	2,
	3;