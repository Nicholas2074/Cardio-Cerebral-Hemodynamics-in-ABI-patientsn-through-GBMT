DROP TABLE IF EXISTS repo_score;
CREATE TABLE repo_score AS -- create columns with only numeric data
WITH vw1 AS (
	SELECT patientunitstayid,
		nursingchartoffset,
		nursingchartentryoffset,
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Glasgow coma score'
			AND nursingchartcelltypevalname = 'GCS Total'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			WHEN nursingchartcelltypecat = 'Other Vital Signs and Infusions'
			AND nursingchartcelltypevallabel = 'Score (Glasgow Coma Scale)'
			AND nursingchartcelltypevalname = 'Value'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS gcs,
		-- //ANCHOR - GCS
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Glasgow coma score'
			AND nursingchartcelltypevalname = 'Motor'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			WHEN nursingchartcelltypecat = 'Other Vital Signs and Infusions'
			AND nursingchartcelltypevallabel = 'Best Motor Response' THEN CASE
				WHEN nursingchartvalue IN ('1', '1-->(M1) none', 'Flaccid') THEN 1
				WHEN nursingchartvalue IN (
					'2',
					'2-->(M2) extension to pain',
					'Abnormal extension'
				) THEN 2
				WHEN nursingchartvalue IN (
					'3',
					'3-->(M3) flexion to pain',
					'Abnormal flexion'
				) THEN 3
				WHEN nursingchartvalue IN ('4', '4-->(M4) withdraws from pain', 'Withdraws') THEN 4
				WHEN nursingchartvalue IN (
					'5',
					'5-->(M5) localizes pain',
					'Localizes to noxious stimuli'
				) THEN 5
				WHEN nursingchartvalue IN (
					'6',
					'6-->(M6) obeys commands',
					'Obeys simple commands'
				) THEN 6
				ELSE NULL
			END
			ELSE NULL
		END AS gcs_motor,
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Glasgow coma score'
			AND nursingchartcelltypevalname = 'Verbal'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			WHEN nursingchartcelltypecat = 'Other Vital Signs and Infusions'
			AND nursingchartcelltypevallabel = 'Best Verbal Response' THEN CASE
				-- when nursingchartvalue in ('Trached or intubated') then 0
				WHEN nursingchartvalue IN (
					'1',
					'1-->(V1) none',
					'None',
					'Clearly unresponsive'
				) THEN 1
				WHEN nursingchartvalue IN (
					'2',
					'2-->(V2) incomprehensible speech',
					'Incomprehensible sounds'
				) THEN 2
				WHEN nursingchartvalue IN (
					'3',
					'3-->(V3) inappropriate words',
					'Inappropriate words'
				) THEN 3
				WHEN nursingchartvalue IN ('4', '4-->(V4) confused', 'Confused') THEN 4
				WHEN nursingchartvalue IN (
					'5',
					'5-->(V5) oriented',
					'Oriented',
					'Orientation/ability to communicate questionable',
					'Clearly oriented/can indicate needs'
				) THEN 5
				ELSE NULL
			END
			ELSE NULL
		END AS gcs_verbal,
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Glasgow coma score'
			AND nursingchartcelltypevalname = 'Eyes'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			WHEN nursingchartcelltypecat = 'Other Vital Signs and Infusions'
			AND nursingchartcelltypevallabel = 'Best Eye Response' THEN CASE
				WHEN nursingchartvalue IN ('1', '1-->(E1) none') THEN 1
				WHEN nursingchartvalue IN ('2', '2-->(E2) to pain') THEN 2
				WHEN nursingchartvalue IN ('3', '3-->(E3) to speech') THEN 3
				WHEN nursingchartvalue IN ('4', '4-->(E4) spontaneous') THEN 4
				ELSE NULL
			END
			ELSE NULL
		END AS gcs_eyes,
		-- unable/other misc info
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Glasgow coma score'
			AND nursingchartcelltypevalname = 'GCS Total'
			AND nursingchartvalue = 'Unable to score due to medication' THEN 1
			ELSE NULL
		END AS gcs_unable,
		CASE
			WHEN nursingchartcelltypecat = 'Other Vital Signs and Infusions'
			AND nursingchartcelltypevallabel = 'Best Verbal Response'
			AND nursingchartvalue = 'Trached or intubated' THEN 1
			ELSE NULL
		END AS gcs_intub,
		-- //ANCHOR - fall risk
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Fall Risk'
			AND nursingchartcelltypevalname = 'Fall Risk' THEN CASE
				WHEN nursingchartvalue = 'Low' THEN 1
				WHEN nursingchartvalue = 'Medium' THEN 2
				WHEN nursingchartvalue = 'High' THEN 3
				ELSE NULL
			END
			ELSE NULL
		END::numeric AS fall_risk,
		-- //ANCHOR - delirium
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Delirium Scale/Score'
			AND nursingchartcelltypevalname = 'Delirium Scale' THEN nursingchartvalue
			ELSE NULL
		END AS delirium_scale,
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Delirium Scale/Score'
			AND nursingchartcelltypevalname = 'Delirium Score' THEN CASE
				WHEN nursingchartvalue IN ('No', 'NO') THEN 0
				WHEN nursingchartvalue IN ('Yes', 'YES') THEN 1
				WHEN nursingchartvalue = 'N/A' THEN NULL
				else cast(nursingchartvalue AS NUMERIC)
			END
			ELSE NULL
		END AS delirium_score,
		-- //ANCHOR - sedation
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Sedation Scale/Score/Goal'
			AND nursingchartcelltypevalname = 'Sedation Scale' THEN nursingchartvalue
			ELSE NULL
		END AS sedation_scale,
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Sedation Scale/Score/Goal'
			AND nursingchartcelltypevalname = 'Sedation Score' THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS sedation_score,
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Sedation Scale/Score/Goal'
			AND nursingchartcelltypevalname = 'Sedation Goal' THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS sedation_goal,
		-- pain
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Pain Score/Goal'
			AND nursingchartcelltypevalname = 'Pain Score' THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS pain_score,
		CASE
			WHEN nursingchartcelltypecat = 'Scores'
			AND nursingchartcelltypevallabel = 'Pain Score/Goal'
			AND nursingchartcelltypevalname = 'Pain Goal' THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS pain_goal
	FROM icu.nursecharting
	WHERE nursingchartcelltypecat IN (
			'Scores',
			'Other Vital Signs and Infusions'
		)
)
SELECT patientunitstayid,
	nursingchartoffset AS chartoffset,
	nursingchartentryoffset AS entryoffset,
	AVG(gcs) AS gcs,
	AVG(gcs_motor) AS gcs_motor,
	AVG(gcs_verbal) AS gcs_verbal,
	AVG(gcs_eyes) AS gcs_eyes,
	MAX(gcs_unable) AS gcs_unable,
	MAX(gcs_intub) AS gcs_intub,
	AVG(fall_risk) AS fall_risk,
	MAX(delirium_scale) AS delirium_scale,
	AVG(delirium_score) AS delirium_score,
	MAX(sedation_scale) AS sedation_scale,
	AVG(sedation_score) AS sedation_score,
	AVG(sedation_goal) AS sedation_goal,
	AVG(pain_score) AS pain_score,
	AVG(pain_goal) AS pain_goal
FROM vw1
WHERE gcs IS NOT NULL
	OR gcs_motor IS NOT NULL
	OR gcs_verbal IS NOT NULL
	OR gcs_eyes IS NOT NULL
	OR gcs_unable IS NOT NULL
	OR gcs_intub IS NOT NULL
	OR fall_risk IS NOT NULL
	OR delirium_scale IS NOT NULL
	OR delirium_score IS NOT NULL
	OR sedation_scale IS NOT NULL
	OR sedation_score IS NOT NULL
	OR sedation_goal IS NOT NULL
	OR pain_score IS NOT NULL
	OR pain_goal IS NOT NULL
GROUP BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset
ORDER BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset;