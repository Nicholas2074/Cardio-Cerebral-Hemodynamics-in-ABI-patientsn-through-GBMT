/* -------------------------------------------------------------------------- */
/* -------------------------------- ATTENTION ------------------------------- */
-- 6 hours before admission and 1 day after admission
-- are both considered as the first day after admission
/* -------------------------------------------------------------------------- */

DROP TABLE IF EXISTS repo_day1_sofa;
CREATE TABLE repo_day1_sofa AS
-- ------------------------------------------------------------------
-- Title: Sequential Organ Failure Assessment (SOFA)
-- This query extracts the sequential organ failure assessment
-- (formerly: sepsis-related organ failure assessment).
-- This score is a measure of organ failure for patients in the ICU.
-- The score is calculated on the first day of each ICU patients' stay.
-- ------------------------------------------------------------------
-- Reference for SOFA:
--    Jean-Louis Vincent, Rui Moreno, Jukka Takala, Sheila Willatts,
--    Arnaldo De Mendonça, Hajo Bruining, C. K. Reinhart, Peter M Suter,
--    and L. G. Thijs.
--    "The SOFA (Sepsis-related Organ Failure Assessment) score to describe
--     organ dysfunction/failure."
--    Intensive care medicine 22, no. 7 (1996): 707-710.
-- Variables used in SOFA:
--  GCS, MAP, FiO2, Ventilation status (sourced from CHARTEVENTS)
--  Creatinine, Bilirubin, FiO2, PaO2, Platelets (sourced from LABEVENTS)
--  Dopamine, Dobutamine, Epinephrine, Norepinephrine (sourced from INPUTEVENTS)
--  Urine output (sourced from OUTPUTEVENTS)
-- The following views required to run this query:
--  1) first_day_urine_output
--  2) first_day_vitalsign
--  3) first_day_gcs
--  4) first_day_lab
--  5) first_day_bg_art
--  6) ventdurations
-- extract drug rates from derived vasopressor tables
WITH vw0 AS (
	SELECT pt.stay_id,
		'norepinephrine' AS treatment,
		vaso_rate AS rate
	FROM icu.icustays pt
		INNER JOIN public.repo_norepinephrine tt ON pt.stay_id = tt.stay_id
		AND tt.starttime >= DATETIME_SUB(pt.intime, INTERVAL '6' HOUR)
		AND tt.starttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
	UNION ALL
	SELECT pt.stay_id,
		'epinephrine' AS treatment,
		vaso_rate AS rate
	FROM icu.icustays pt
		INNER JOIN public.repo_epinephrine tt ON pt.stay_id = tt.stay_id
		AND tt.starttime >= DATETIME_SUB(pt.intime, INTERVAL '6' HOUR)
		AND tt.starttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
	UNION ALL
	SELECT pt.stay_id,
		'dobutamine' AS treatment,
		vaso_rate AS rate
	FROM icu.icustays pt
		INNER JOIN public.repo_dobutamine tt ON pt.stay_id = tt.stay_id
		AND tt.starttime >= DATETIME_SUB(pt.intime, INTERVAL '6' HOUR)
		AND tt.starttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
	UNION ALL
	SELECT pt.stay_id,
		'dopamine' AS treatment,
		vaso_rate AS rate
	FROM icu.icustays pt
		INNER JOIN public.repo_dopamine tt ON pt.stay_id = tt.stay_id
		AND tt.starttime >= DATETIME_SUB(pt.intime, INTERVAL '6' HOUR)
		AND tt.starttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
),
vw1 AS (
	SELECT pt.stay_id,
		MAX(
			CASE
				WHEN tt.treatment = 'norepinephrine' THEN rate
				ELSE NULL
			END
		) AS rate_norepinephrine,
		MAX(
			CASE
				WHEN tt.treatment = 'epinephrine' THEN rate
				ELSE NULL
			END
		) AS rate_epinephrine,
		MAX(
			CASE
				WHEN tt.treatment = 'dopamine' THEN rate
				ELSE NULL
			END
		) AS rate_dopamine,
		MAX(
			CASE
				WHEN tt.treatment = 'dobutamine' THEN rate
				ELSE NULL
			END
		) AS rate_dobutamine
	FROM icu.icustays pt
		LEFT JOIN vw0 tt ON pt.stay_id = tt.stay_id
	GROUP BY pt.stay_id
),
vw2 AS (
	-- join blood gas to ventilation durations to determine if patient was vent
	SELECT pt.stay_id,
		t2.charttime,
		t2.pao2fio2ratio,
		CASE
			WHEN t3.stay_id IS NOT NULL THEN 1
			ELSE 0
		END AS isvent
	FROM icu.icustays pt
		LEFT JOIN public.repo_bg t2 ON pt.subject_id = t2.subject_id
		AND t2.charttime >= DATETIME_SUB(pt.intime, INTERVAL '6' HOUR)
		AND t2.charttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
		LEFT JOIN public.repo_ventilation t3 ON pt.stay_id = t3.stay_id
		AND t2.charttime >= t3.starttime
		AND t2.charttime <= t3.endtime
		AND t3.ventilation_status = 'InvasiveVent'
),
vw3 AS (
	-- because pafi has an interaction between vent/PaO2:FiO2,
	-- we need two columns for the score
	-- it can happen that the lowest unventilated PaO2/FiO2 is 68, 
	-- but the lowest ventilated PaO2/FiO2 is 120
	-- in this case, the SOFA score is 3, *not* 4.
	SELECT stay_id,
		MIN(
			CASE
				WHEN isvent = 0 THEN pao2fio2ratio
				ELSE NULL
			END
		) AS pao2fio2_novent_min,
		MIN(
			CASE
				WHEN isvent = 1 THEN pao2fio2ratio
				ELSE NULL
			END
		) AS pao2fio2_vent_min
	FROM vw2
	GROUP BY stay_id
),
vw4 AS (
	SELECT pt.stay_id,
		MIN(tt.nimbp) AS nimbp_min,
		MIN(tt.imbp) AS imbp_min
	FROM icu.icustays pt
	LEFT JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
	AND tt.charttime >= DATETIME_SUB(pt.intime, INTERVAL '6' HOUR)
	AND tt.charttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
	GROUP BY pt.stay_id
),
vw5 AS (
	SELECT pt.stay_id,
		MAX(tt.creatinine) AS creatinine_max,
		MAX(tt.tbil) AS bilirubin_max
	FROM icu.icustays pt
	LEFT JOIN public.repo_chemistry tt ON pt.hadm_id = tt.hadm_id
	AND tt.charttime >= DATETIME_SUB(pt.intime, INTERVAL '1' DAY)
	AND tt.charttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
	GROUP BY pt.stay_id
),
vw6 AS (
	SELECT pt.stay_id,
		MIN(tt.pla) AS platelet_min
	FROM icu.icustays pt
	LEFT JOIN public.repo_blood_diff tt ON pt.hadm_id = tt.hadm_id
	AND tt.charttime >= DATETIME_SUB(pt.intime, INTERVAL '1' DAY)
	AND tt.charttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
	GROUP BY pt.stay_id
),
vw7 AS (
	SELECT pt.stay_id,
		MIN(tt.gcs) AS gcs_min
	FROM icu.icustays pt
	LEFT JOIN public.repo_gcs tt ON pt.stay_id = tt.stay_id
	AND tt.charttime >= DATETIME_SUB(pt.intime, INTERVAL '6' HOUR)
	AND tt.charttime <= DATETIME_ADD(pt.intime, INTERVAL '1' DAY)
	GROUP BY pt.stay_id
),
-- Aggregate the components for the score
scorecomp AS (
	SELECT pt.stay_id,
		vw1.rate_norepinephrine,
		vw1.rate_epinephrine,
		vw1.rate_dopamine,
		vw1.rate_dobutamine,
		vw3.pao2fio2_novent_min,
		vw3.pao2fio2_vent_min,
		CASE
			WHEN vw4.nimbp_min < vw4.imbp_min THEN vw4.nimbp_min
			WHEN vw4.imbp_min < vw4.nimbp_min THEN vw4.imbp_min
			ELSE NULL
		END AS mbp_min,
		vw5.creatinine_max,
		vw5.bilirubin_max,
		vw6.platelet_min,
		vw7.gcs_min,
		tt.urineoutput
	FROM icu.icustays pt
		LEFT JOIN vw1 ON pt.stay_id = vw1.stay_id
		LEFT JOIN vw3 ON pt.stay_id = vw3.stay_id
		LEFT JOIN vw4 ON pt.stay_id = vw4.stay_id
		LEFT JOIN vw5 ON pt.stay_id = vw5.stay_id
		LEFT JOIN vw6 ON pt.stay_id = vw6.stay_id
		LEFT JOIN vw7 ON pt.stay_id = vw7.stay_id
		LEFT JOIN public.repo_day1_urine_output tt ON pt.stay_id = tt.stay_id
),
scorecalc AS (
	-- Calculate the final score
	-- note that if the underlying data is missing, the component is null
	-- eventually these are treated as 0 (normal), but knowing when data
	-- is missing is useful for debugging
	SELECT stay_id,
	-- Respiration
		CASE
			WHEN pao2fio2_vent_min < 100 THEN 4
			WHEN pao2fio2_vent_min < 200 THEN 3
			WHEN pao2fio2_novent_min < 300 THEN 2
			WHEN pao2fio2_novent_min < 400 THEN 1
			WHEN COALESCE(
				pao2fio2_vent_min,
				pao2fio2_novent_min
			) IS NULL THEN NULL
			ELSE 0
		END AS respiration,
		-- Coagulation
		CASE
			WHEN platelet_min < 20 THEN 4
			WHEN platelet_min < 50 THEN 3
			WHEN platelet_min < 100 THEN 2
			WHEN platelet_min < 150 THEN 1
			WHEN platelet_min IS NULL THEN NULL
			ELSE 0
		END AS coagulation,
		-- Liver
		CASE
			-- Bilirubin checks in mg/dL
			WHEN bilirubin_max >= 12.0 THEN 4
			WHEN bilirubin_max >= 6.0 THEN 3
			WHEN bilirubin_max >= 2.0 THEN 2
			WHEN bilirubin_max >= 1.2 THEN 1
			WHEN bilirubin_max IS NULL THEN NULL
			ELSE 0
		END AS liver,
		-- Cardiovascular
		CASE
			WHEN rate_dopamine > 15
			OR rate_epinephrine > 0.1
			OR rate_norepinephrine > 0.1 THEN 4
			WHEN rate_dopamine > 5
			OR rate_epinephrine <= 0.1
			OR rate_norepinephrine <= 0.1 THEN 3
			WHEN rate_dopamine > 0
			OR rate_dobutamine > 0 THEN 2
			WHEN mbp_min < 70 THEN 1
			WHEN COALESCE(
				mbp_min,
				rate_dopamine,
				rate_dobutamine,
				rate_epinephrine,
				rate_norepinephrine
			) IS NULL THEN NULL
			ELSE 0
		END AS cardiovascular,
		-- Neurological failure (GCS)
		CASE
			WHEN (
				gcs_min >= 13
				AND gcs_min <= 14
			) THEN 1
			WHEN (
				gcs_min >= 10
				AND gcs_min <= 12
			) THEN 2
			WHEN (
				gcs_min >= 6
				AND gcs_min <= 9
			) THEN 3
			WHEN gcs_min < 6 THEN 4
			WHEN gcs_min IS NULL THEN NULL
			ELSE 0
		END AS cns,
		-- Renal failure - high creatinine or low urine output
		CASE
			WHEN (creatinine_max >= 5.0) THEN 4
			WHEN urineoutput < 200 THEN 4
			WHEN (
				creatinine_max >= 3.5
				AND creatinine_max < 5.0
			) THEN 3
			WHEN urineoutput < 500 THEN 3
			WHEN (
				creatinine_max >= 2.0
				AND creatinine_max < 3.5
			) THEN 2
			WHEN (
				creatinine_max >= 1.2
				AND creatinine_max < 2.0
			) THEN 1
			WHEN COALESCE(urineoutput, creatinine_max) IS NULL THEN NULL
			ELSE 0
		END AS renal
	FROM scorecomp
)
SELECT pt.subject_id,
	pt.hadm_id,
	pt.stay_id, 
	-- Combine all the scores to get SOFA
	-- Impute 0 if the score is missing
	COALESCE(tt.respiration, 0)
	+ COALESCE(tt.coagulation, 0)
	+ COALESCE(tt.liver, 0)
	+ COALESCE(tt.cardiovascular, 0)
	+ COALESCE(tt.cns, 0)
	+ COALESCE(tt.renal, 0) AS sofa,
	tt.respiration,
	tt.coagulation,
	tt.liver,
	tt.cardiovascular,
	tt.cns,
	tt.renal
FROM icu.icustays pt
	LEFT JOIN scorecalc tt ON pt.stay_id = tt.stay_id;