DROP TABLE IF EXISTS repo_lipid;
CREATE TABLE repo_lipid AS
SELECT subject_id,
	hadm_id,
	specimen_id,
	charttime,
	-- convert from itemid into a meaningful column
	MAX(
		CASE
			WHEN itemid = 51000 -- mg/dL
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS tg,
	MAX(
		CASE
			WHEN itemid = 50907
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS tcho,
	MAX(
		CASE
			WHEN itemid = 50904
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS hdl,
	MAX(
		CASE
			WHEN itemid IN (50905, 50906)
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS ldl
FROM hosp.labevents
WHERE itemid IN (
	51000,
	50907,
	50904,
	50905,
	50906
	)
	AND valuenum IS NOT NULL -- lab values cannot be 0 and cannot be negative
GROUP BY subject_id,
	hadm_id,
	specimen_id,
	charttime;