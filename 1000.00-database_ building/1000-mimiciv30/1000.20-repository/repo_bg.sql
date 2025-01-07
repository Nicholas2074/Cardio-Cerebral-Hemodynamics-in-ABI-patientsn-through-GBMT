DROP TABLE IF EXISTS repo_bg;
CREATE TABLE repo_bg AS
-- The aim of this query is to pivot entries related to blood gases
-- which were found in LABEVENTS
WITH bg AS (
	SELECT -- specimen_id only ever has 1 measurement for each itemid
		-- so, we may simply collapse rows using MAX()
		subject_id,
		hadm_id,
		specimen_id,
		charttime, -- specimen_id *may* have different storetimes, so this
		-- is taking the latest
		storetime,
		MAX(
			CASE
				WHEN itemid = 52033 THEN value
				ELSE NULL
			END
		) AS specimen,
		MAX(
			CASE
				WHEN itemid = 50801 THEN valuenum
				ELSE NULL
			END
		) AS aado2,
		MAX(
			CASE
				WHEN itemid IN (50868, 52500) THEN valuenum
				ELSE NULL
			END
		) AS aniongap,
		MAX(
			CASE
				WHEN itemid = 50803 THEN valuenum
				ELSE NULL
			END
		) AS bicarbonate,
		MAX(
			CASE
				WHEN itemid = 50802 THEN valuenum
				ELSE NULL
			END
		) AS baseexcess,
		MAX(
			CASE
				WHEN itemid = 50804 THEN valuenum
				ELSE NULL
			END
		) AS totalco2,
		MAX(
			CASE
				WHEN itemid = 50805 THEN valuenum
				ELSE NULL
			END
		) AS carboxyhemoglobin,
		MAX(
			CASE
				WHEN itemid = 50806 THEN valuenum
				ELSE NULL
			END
		) AS chloride,
		MAX(
			CASE
				WHEN itemid = 50808 THEN valuenum
				ELSE NULL
			END
		) AS calcium,
		MAX(
			CASE
				WHEN itemid = 50809
				AND valuenum <= 10000 THEN valuenum
				ELSE NULL
			END
		) AS glucose,
		MAX(
			CASE
				WHEN itemid = 50810
				AND valuenum <= 100 THEN valuenum
				ELSE NULL
			END
		) AS hematocrit,
		MAX(
			CASE
				WHEN itemid = 50811 THEN valuenum
				ELSE NULL
			END
		) AS hemoglobin,
		MAX(
			CASE
				WHEN itemid = 50813
				AND valuenum <= 10000 THEN valuenum
				ELSE NULL
			END
		) AS lactate,
		MAX(
			CASE
				WHEN itemid = 50814 THEN valuenum
				ELSE NULL
			END
		) AS methemoglobin,
		MAX(
			CASE
				WHEN itemid = 50815 THEN valuenum
				ELSE NULL
			END
		) AS o2flow, -- fix a common unit conversion error for fio2
		-- atmospheric o2 is 20.89%, so any value <= 20 is unphysiologic
		-- usually this is a misplaced O2 flow measurement
		MAX(
			CASE
				WHEN itemid = 50816 THEN CASE
					WHEN valuenum > 20
					AND valuenum <= 100 THEN valuenum
					WHEN valuenum > 0.2
					AND valuenum <= 1.0 THEN valuenum * 100.0
					ELSE NULL
				END
				ELSE NULL
			END
		) AS fio2,
		MAX(
			CASE
				WHEN itemid = 50817
				AND valuenum <= 100 THEN valuenum
				ELSE NULL
			END
		) AS sao2,
		MAX(
			CASE
				WHEN itemid = 50818 THEN valuenum
				ELSE NULL
			END
		) AS paco2,
		MAX(
			CASE
				WHEN itemid = 50819 THEN valuenum
				ELSE NULL
			END
		) AS peep,
		MAX(
			CASE
				WHEN itemid = 50820 THEN valuenum
				ELSE NULL
			END
		) AS ph,
		MAX(
			CASE
				WHEN itemid = 50821 THEN valuenum
				ELSE NULL
			END
		) AS pao2,
		MAX(
			CASE
				WHEN itemid = 50822 THEN valuenum
				ELSE NULL
			END
		) AS potassium,
		MAX(
			CASE
				WHEN itemid = 50823 THEN valuenum
				ELSE NULL
			END
		) AS requiredo2,
		MAX(
			CASE
				WHEN itemid = 50824 THEN valuenum
				ELSE NULL
			END
		) AS sodium,
		MAX(
			CASE
				WHEN itemid = 50825 THEN valuenum
				ELSE NULL
			END
		) AS temperature,
		MAX(
			CASE
				WHEN itemid = 50807 THEN value
				ELSE NULL
			END
		) AS comments
	FROM hosp.labevents
	WHERE itemid IN -- blood gases
		(
			52033, -- specimen
			50801, -- aado2
			50868, -- aniongap
			52500, -- aniongap
			50803, -- bicarb
			50802, -- base excess
			50804, -- calc tot co2
			50805, -- carboxyhgb
			50806, -- chloride
			-- 52390, -- chloride, WB CL-
			50807, -- comments
			50808, -- free calcium
			50809, -- glucose
			50810, -- hct
			50811, -- hgb
			50813, -- lactate
			50814, -- methemoglobin
			50815, -- o2 flow
			50816, -- fio2
			50817, -- o2 sat
			50818, -- paco2
			50819, -- peep
			50820, -- pH
			50821, -- pao2
			50822, -- potassium
			-- 52408, -- potassium, WB K+
			50823, -- required O2
			50824, -- sodium
			-- 52411, -- sodium, WB NA +
			50825 -- temperature
		)
	GROUP BY subject_id,
		hadm_id,
		specimen_id,
		charttime,
		storetime
),
stg_spao2 AS (
	SELECT subject_id,
		charttime, -- avg here is just used to group SpO2 by charttime
		AVG(valuenum) AS spao2
	FROM icu.chartevents
	WHERE itemid = 220277 -- O2 saturation pulseoxymetry
		AND valuenum > 0
		AND valuenum <= 100
	GROUP BY subject_id,
		charttime
),
stg_fio2 AS (
	SELECT subject_id,
		charttime, -- pre-process the FiO2s to ensure they are between 21-100%
		MAX(
			CASE
				WHEN valuenum > 0.2
				AND valuenum <= 1 THEN valuenum * 100 -- improperly input data - looks like O2 flow in litres
				WHEN valuenum > 1
				AND valuenum < 20 THEN NULL
				WHEN valuenum >= 20
				AND valuenum <= 100 THEN valuenum
				ELSE NULL
			END
		) AS fio2_chartevents
	FROM icu.chartevents
	WHERE itemid = 223835 -- Inspired O2 Fraction (FiO2)
		AND valuenum > 0
		AND valuenum <= 100
	GROUP BY subject_id,
		charttime
),
stg2 AS (
	SELECT bg.*,
		ROW_NUMBER() OVER (
			PARTITION BY bg.subject_id,
			bg.charttime
			ORDER BY s1.charttime DESC
		) AS lastrowspao2,
		s1.spao2
	FROM bg
		LEFT JOIN stg_spao2 s1 -- same hospitalization
		ON bg.subject_id = s1.subject_id -- spao2 occurred at most 2 hours before this blood gas
		AND s1.charttime BETWEEN DATETIME_SUB(bg.charttime, INTERVAL '2' HOUR)
		AND bg.charttime
	WHERE bg.pao2 IS NOT NULL
),
stg3 AS (
	SELECT bg.*,
		ROW_NUMBER() OVER (
			PARTITION BY bg.subject_id,
			bg.charttime
			ORDER BY s2.charttime DESC
		) AS lastrowfio2,
		s2.fio2_chartevents
	FROM stg2 bg
		LEFT JOIN stg_fio2 s2 -- same patient
		ON bg.subject_id = s2.subject_id -- fio2 occurred at most 4 hours before this blood gas
		AND s2.charttime >= DATETIME_SUB(bg.charttime, INTERVAL '4' HOUR)
		AND s2.charttime <= bg.charttime
		AND s2.fio2_chartevents > 0 -- only the row with the most recent SpO2 (if no SpO2 found lastRowSpO2 = 1)
	WHERE bg.lastrowspao2 = 1
)
SELECT subject_id,
	hadm_id,
	charttime, -- drop down text indicating the specimen type
	specimen, -- oxygen related parameters
	sao2,
	pao2,
	paco2,
	fio2_chartevents,
	fio2,
	aado2, -- also calculate AADO2
	CASE
		WHEN pao2 IS NULL
		OR paco2 IS NULL THEN NULL
		WHEN fio2 IS NOT NULL -- multiple by 100 because fio2 is in a % but should be a fraction
		THEN (fio2 / 100) * (760 - 47) - (paco2 / 0.8) - pao2
		WHEN fio2_chartevents IS NOT NULL THEN (fio2_chartevents / 100) * (760 - 47) - (paco2 / 0.8) - pao2
		ELSE NULL
	END AS aado2_calc,
	CASE
		WHEN pao2 IS NULL THEN NULL
		WHEN fio2 IS NOT NULL -- multiply by 100 because fio2 is in a % but should be a fraction
		THEN 100 * pao2 / fio2
		WHEN fio2_chartevents IS NOT NULL -- multiply by 100 because fio2 is in a % but should be a fraction
		THEN 100 * pao2 / fio2_chartevents
		ELSE NULL
	END AS pao2fio2ratio, -- acid-base parameters
	ph,
	aniongap,
	bicarbonate,
	baseexcess,
	totalco2, -- blood count parameters
	hematocrit,
	hemoglobin,
	carboxyhemoglobin,
	methemoglobin, -- chemistry
	chloride,
	calcium,
	temperature,
	potassium,
	sodium,
	lactate,
	glucose 
	-- ventilation stuff that's sometimes input
	-- intubated, tidalvolume, ventilationrate, ventilator,
	peep,
	o2flow
	-- requiredo2,
FROM stg3
WHERE lastrowfio2 = 1 -- only the most recent FiO2
;