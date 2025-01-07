DROP TABLE IF EXISTS repo_cardiac;
CREATE TABLE repo_cardiac AS -- begin query that extracts the data
SELECT subject_id,
	hadm_id,
	specimen_id,
	charttime,
	-- convert from itemid into a meaningful column
	MAX(
		CASE
			WHEN itemid = 50911 THEN valuenum
			ELSE NULL
		END
	) AS ck_mb,
	MAX(
		CASE
			WHEN itemid = 50908 THEN valuenum
			ELSE NULL
		END
	) AS ck_mb_index,
	MAX(
		CASE
			WHEN itemid = 50910 THEN valuenum
			ELSE NULL
		END
	) AS ck,
	MAX(
		CASE
			WHEN itemid = 51003 THEN valuenum
			ELSE NULL
		END
	) AS ctnt,
	MAX(
		CASE
			WHEN itemid = 50963 THEN valuenum
			ELSE NULL
		END
	) AS ntprobnp
FROM hosp.labevents
WHERE itemid IN (
		50911, -- creatinine kinase, mb isoenzyme
		50908, --ck_mb index, | blood | chemistry
		-- 51580, calculated ck_mb, discarded
		50910, -- creatinine kinase(ck)
		-- 52598, -- troponin i, point of care, rare/poor quality
		-- 51002, -- troponin i (troponin-i is not measured in mimic-iv)
		51003, -- troponin t
		50963 -- n-terminal (nt)-pro hormone bnp (nt-probnp) 
	)
	AND valuenum IS NOT NULL
GROUP BY subject_id,
	hadm_id,
	specimen_id,
	charttime;