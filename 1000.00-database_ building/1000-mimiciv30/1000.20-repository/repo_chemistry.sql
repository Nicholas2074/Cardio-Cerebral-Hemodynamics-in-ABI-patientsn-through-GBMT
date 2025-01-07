DROP TABLE IF EXISTS repo_chemistry;
CREATE TABLE repo_chemistry AS
-- extract chemistry labs
-- excludes point of care tests (very rare)
-- blood gas measurements are *not* included in this query
-- instead they are in bg.sql
SELECT subject_id,
	hadm_id,
	specimen_id,
	charttime,
	-- convert from itemid into a meaningful column
	MAX(
		CASE
			WHEN itemid IN ('50931', '52569')
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS glucose,
	MAX(
		CASE
			WHEN itemid = 50861
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS alt,
	MAX(
		CASE
			WHEN itemid = 50878
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS ast,
	MAX(
		CASE
			WHEN itemid = 50863
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS alp,
	MAX(
		CASE
			WHEN itemid = 50883
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS dbil,
	MAX(
		CASE
			WHEN itemid = 50884
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS ibil,
	MAX(
		CASE
			WHEN itemid = 50885
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS tbil,
	MAX(
		CASE
			WHEN itemid = 50862
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS albumin,
	MAX(
		CASE
			WHEN itemid = 50930
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS globulin,
	MAX(
		CASE
			WHEN itemid = 50976
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS total_protein,
	MAX(
		CASE
			WHEN itemid = 50912
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS creatinine,
	MAX(
		CASE
			WHEN itemid = 51006
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS bun,
	MAX(
		CASE
			WHEN itemid = 50868
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS aniongap,
	MAX(
		CASE
			WHEN itemid = 50882
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS bicarbonate,
	MAX(
		CASE
			WHEN itemid = 50983
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS sodium,
	MAX(
		CASE
			WHEN itemid = 50971
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS potassium,
	MAX(
		CASE
			WHEN itemid = 50893
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS calcium,
	MAX(
		CASE
			WHEN itemid = 50902
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS chloride,
	MAX(
		CASE
			WHEN itemid = 50960
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS magnesium,
	MAX(
		CASE
			WHEN itemid = 50960
			AND valuenum > 0 THEN valuenum
			ELSE NULL
		END
	) AS phosphate
FROM hosp.labevents
WHERE itemid IN (
		-- comment is: label | category | fluid
		50931, -- glucose | chemistry | blood, mg/dL
		-- 52525, glucose, point of care
		50861, -- alt | chemistry | blood
		50878, -- ast | chemistry | blood
		50883, -- dbil | chemistry | blood
		50884, -- ibil | chemistry | blood
		50885, -- tbil | chemistry | blood
		50863, -- alp(Alkaline Phosphatase) | chemistry | blood
		50862, -- albumin | chemistry | blood
		50930, -- globulin
		50976, -- total protein
		-- 52502, creatinine, point of care
		50912, -- creatinine | chemistry | blood
		51006, -- urea nitrogen | chemistry | blood
		-- 52456, -- anion gap, point of care test
		50868, -- anion gap | chemistry | blood
		50882, -- bicarbonate | chemistry | blood
		-- 52579, -- sodium, point of care
		50983, -- sodium | chemistry | blood
		-- 52566, -- potassium, point of care
		50971, -- potassium | chemistry | blood
		50893, -- calcium | chemistry | blood
		50902, -- chloride | chemistry | blood
		50960, -- magnesium | chemistry | blood
		50970 -- phosphate | chemistry | blood
	)
	AND valuenum IS NOT NULL -- lab values cannot be 0 and cannot be negative
	-- .. except anion gap.
	AND (
		valuenum > 0
		OR itemid = 50868
	)
GROUP BY subject_id,
	hadm_id,
	specimen_id,
	charttime;