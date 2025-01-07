DROP TABLE IF EXISTS repo_coagulation;
CREATE TABLE repo_coagulation AS
SELECT subject_id,
	hadm_id,
	specimen_id, 
	charttime,
	-- convert from itemid into a meaningful column
	MAX(
		CASE
			WHEN itemid = 51237 THEN valuenum
			ELSE NULL
		END
	) AS inr,
	MAX(
		CASE
			WHEN itemid = 51274 THEN valuenum
			ELSE NULL
		END
	) AS pt,
	MAX(
		CASE
			WHEN itemid = 51275 THEN valuenum
			ELSE NULL
		END
	) AS ptt,
	MAX(
		CASE
			WHEN itemid = 51196 THEN valuenum
			ELSE NULL
		END
	) AS d_dimer,
	MAX(
		CASE
			WHEN itemid = 51214 THEN valuenum
			ELSE NULL
		END
	) AS fibrinogen,
	MAX(
		CASE
			WHEN itemid = 51297 THEN valuenum
			ELSE NULL
		END
	) AS thrombin
FROM hosp.labevents
WHERE itemid IN (
		51237, -- INR
		51274, -- PT
		51275, -- PTT
		-- Bleeding Time, no data as of MIMIC-IV v0.4
		-- 51149, 52750, 52072, 52073
		51196, -- D-Dimer
		51214, -- Fibrinogen
		-- Reptilase Time, no data as of MIMIC-IV v0.4
		-- 51280, 52893,
		-- Reptilase Time Control, no data as of MIMIC-IV v0.4
		-- 51281, 52161,
		51297 -- thrombin
	)
	AND valuenum IS NOT NULL
GROUP BY subject_id,
	hadm_id,
	specimen_id,
	charttime;