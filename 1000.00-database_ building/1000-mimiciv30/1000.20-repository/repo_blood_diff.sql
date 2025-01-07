/* -------------------------------------------------------------------------- */
-- this table contains indicators in 
-- oringinal blood_differential and complete_blood_count
/* -------------------------------------------------------------------------- */

-- oringinal complete_blood_count includes indicators of
-- hematocrit
-- hemoglobin
-- mch
-- mchc
-- mcv
-- platelet
-- rbc
-- rdw
-- rdwsd
-- wbc

-- oringinal blood_differential includes indicators of
-- wbc
-- basophils_abs
-- eosinophils_abs
-- lymphocytes_abs
-- monocytes_abs
-- neutrophils_abs
-- basophils
-- eosinophils
-- lymphocytes
-- monocytes
-- neutrophils
-- atypical_lymphocytes
-- bands
-- immature_granulocytes
-- metamyelocytes
-- nrbc

DROP TABLE IF EXISTS repo_blood_diff;
CREATE TABLE repo_blood_diff AS
-- For reference, some common unit conversions:
-- 10^9/l == k/ul == 10^3k/ul
WITH blood_diff AS (
	SELECT subject_id,
		hadm_id,
		specimen_id,
		charttime,
		-- create one set of columns for percentages, one set for counts
		-- we harmonize all count units into k/ul == 10^9/l
		-- counts have an "_abs" suffix, percentages do not
		-- absolute counts
		MAX(
			CASE
				WHEN itemid IN (51300, 51301, 51755) THEN valuenum
				ELSE NULL
			END
		) AS wbc,
		MAX(
			CASE
				WHEN itemid = 52075 THEN valuenum
				ELSE NULL
			END
		) AS neutrophils_abs, -- convert from #k/ul to k/ul
		MAX(
			CASE
				WHEN itemid = 51133 THEN valuenum
				WHEN itemid = 52769 THEN valuenum / 1000.0 -- 51133 in k/ul, 52769 in #k/ul
				ELSE NULL
			END
		) AS lymphocytes_abs, -- 52074 in k/ul, 51253 in #k/ul
		MAX(
			CASE
				WHEN itemid = 52074 THEN valuenum
				WHEN itemid = 51253 THEN valuenum / 1000.0
				ELSE NULL
			END
		) AS monocytes_abs,
		MAX(
			CASE
				WHEN itemid = 52069 THEN valuenum
				ELSE NULL
			END
		) AS basophils_abs, 
		MAX(
			CASE
				WHEN itemid = 52073 THEN valuenum
				WHEN itemid = 51199 THEN valuenum / 1000.0 -- 52073 in k/ul, 51199 in #k/ul
				ELSE NULL
			END
		) AS eosinophils_abs,
		MAX(
			CASE
				WHEN itemid = 51218 THEN valuenum / 1000.0
				ELSE NULL
			END
		) AS granulocytes_abs, -- percentages, equal to cell count / white blood cell count
		MAX(
			CASE
				WHEN itemid = 51256 THEN valuenum
				ELSE NULL
			END
		) AS neutrophils, -- other cell count percentages
		MAX(
			CASE
				WHEN itemid IN (51244, 51245) THEN valuenum
				ELSE NULL
			END
		) AS lymphocytes,
		MAX(
			CASE
				WHEN itemid = 51254 THEN valuenum
				ELSE NULL
			END
		) AS monocytes,
		MAX(
			CASE
				WHEN itemid = 51144 THEN valuenum
				ELSE NULL
			END
		) AS bands,
		MAX(
			CASE
				WHEN itemid = 51146 THEN valuenum
				ELSE NULL
			END
		) AS basophils,
		MAX(
			CASE
				WHEN itemid = 51200 THEN valuenum
				ELSE NULL
			END
		) AS eosinophils,
		MAX(
			CASE
				WHEN itemid = 51143 THEN valuenum
				ELSE NULL
			END
		) AS atypical_lymphocytes,
		MAX(
			CASE
				WHEN itemid = 52135 THEN valuenum
				ELSE NULL
			END
		) AS immature_granulocytes,
		MAX(
			CASE
				WHEN itemid = 51251 THEN valuenum
				ELSE NULL
			END
		) AS metamyelocytes,
		MAX(
			CASE
				WHEN itemid = 51257 THEN valuenum
				ELSE NULL
			END
		) AS nrbc, -- utility flags which determine whether imputation is possible
		MAX(
			CASE
				WHEN itemid = 51279 THEN valuenum
				ELSE NULL
			END
		) AS rbc,
		MAX(
			CASE
				WHEN itemid = 52177 THEN valuenum
				ELSE NULL
			END
		) AS rdw,
		MAX(
			CASE
				WHEN itemid = 51248 THEN valuenum
				ELSE NULL
			END
		) AS mch,
		MAX(
			CASE
				WHEN itemid = 51249 THEN valuenum
				ELSE NULL
			END
		) AS mchc,
		MAX(
			CASE
				WHEN itemid = 51221 THEN valuenum
				ELSE NULL
			END
		) AS hct,
		MAX(
			CASE
				WHEN itemid = 51222 THEN valuenum
				ELSE NULL
			END
		) AS hgb,
		MAX(
			CASE
				WHEN itemid = 50852 THEN valuenum
				ELSE NULL
			END
		) AS hgb_a1c,
		MAX(
			CASE
				WHEN itemid = 51265 THEN valuenum
				ELSE NULL
			END
		) AS pla,
		MAX(
			CASE
				WHEN itemid = 50889 THEN valuenum
				ELSE NULL
			END
		) AS crp,
		MAX(
			CASE
				WHEN itemid = 51652 THEN valuenum
				ELSE NULL
			END
		) AS crp_hs,
		CASE
			-- WBC is available
			WHEN MAX(
				CASE
					WHEN itemid IN (51300, 51301, 51755) THEN valuenum
					ELSE NULL
				END
			) > 0 
			-- and we have at least one percentage from the diff
			-- sometimes the entire diff is 0%, which looks like bad data
			AND SUM(
				CASE
					WHEN itemid IN (
						51146,
						51200,
						51244,
						51245,
						51254,
						51256
					) THEN valuenum
					ELSE NULL
				END
			) > 0 THEN 1
			ELSE 0
		END AS impute_abs
	FROM hosp.labevents
	WHERE itemid IN (
			-- wbc totals measured in k/ul
			-- 52220 (wbcp) is percentage
			51300, -- wbc, k/ul
			51301, -- wbc, k/ul
			51755, -- wbc, k/ul
			52075, -- neutrophils_abs, k/ul
			51133, -- lymphocytes_abs, k/ul
			52769, -- lymphocytes_abs, #k/ul
			52074, -- monocytes_abs, k/ul
			51253, -- monocytes_abs, #k/ul
			52069, -- basophils_abs, k/ul
			52073, -- eosinophils_abs, k/ul
			51199, -- eosinophils_abs, #k/ul
			51218, -- granulocytes_abs, #k/ul
			51256, -- neutrophils, %
			51244, -- lymphocytes, %
			51245, -- lymphocytes, %
			51254, -- monocytes, %
			51144, -- bands, %
			51146, -- basophils, %
			51200, -- eosinophils, %
			51143, -- atypical_lymphocytes, %
			52135, -- immature_granulocytes(%), %
			51251, -- metamyelocytes, %
			51257, -- nrbc, %
			51279, -- rbc, mk/ul
			52177, -- rdw, %
			51248, -- mch, pg
			51249, -- mchc, %
			51221, -- hct
			51222, -- Hemoglobin, g/dl | blood | hematology
			50852, -- % hemoglobin a1c, % | blood | chemistry
			-- 51631, -- glycated hemoglobin, discarded, no data
			-- 50855, -- absolute hemoglobin, discarded, no data
			-- 51640, -- hemoglobin, discarded, no data
			-- 51641, -- hemoglobin a, discarded, no data
			-- 51642, -- hemoglobin a1, discarded, no data
			-- 51643, -- hemoglobin a2, discarded, no data
			-- 51644, -- hemoglobin c, discarded, no data
			-- 51645, -- hemoglobin calculated, discarded, no data
			-- 51646, -- hemoglobin f, discarded, no data
			51265, -- platelets
			50889, -- crp, mg/l
			51652 -- crp_hs, mg/l
			-- below are point of care tests which are extremely infrequent
			-- and usually low quality
			-- 51697, -- Neutrophils (mmol/l)
			-- below itemid do not have data as of MIMIC-IV v1.0
			-- 51536, -- Absolute Lymphocyte Count
			-- 51537, -- Absolute Neutrophil
			-- 51690, -- Lymphocytes
			-- 52151, -- NRBC
		)
		AND valuenum IS NOT NULL -- differential values cannot be negative
		AND valuenum >= 0
	GROUP BY subject_id,
		hadm_id,
		specimen_id,
		charttime
)
SELECT subject_id,
	hadm_id,
	charttime,
	specimen_id,
	wbc, -- impute absolute count if percentage & WBC is available
	ROUND(
		CAST(
			CASE
				WHEN neutrophils_abs IS NULL
				AND neutrophils IS NOT NULL
				AND impute_abs = 1 THEN neutrophils * wbc / 100
				ELSE neutrophils_abs
			END AS NUMERIC
		), 4
	) AS neutrophils_abs,
	ROUND(
		CAST(
			CASE
				WHEN lymphocytes_abs IS NULL
				AND lymphocytes IS NOT NULL
				AND impute_abs = 1 THEN lymphocytes * wbc / 100
				ELSE lymphocytes_abs
			END AS NUMERIC
		), 4
	) AS lymphocytes_abs,
	ROUND(
		CAST(
			CASE
				WHEN monocytes_abs IS NULL
				AND monocytes IS NOT NULL
				AND impute_abs = 1 THEN monocytes * wbc / 100
				ELSE monocytes_abs
			END AS NUMERIC
		), 4
	) AS monocytes_abs,
	ROUND(
		CAST(
			CASE
				WHEN basophils_abs IS NULL
				AND basophils IS NOT NULL
				AND impute_abs = 1 THEN basophils * wbc / 100
				ELSE basophils_abs
			END AS NUMERIC
		), 4
	) AS basophils_abs,
	ROUND(
		CAST(
			CASE
				WHEN eosinophils_abs IS NULL
				AND eosinophils IS NOT NULL
				AND impute_abs = 1 THEN eosinophils * wbc / 100
				ELSE eosinophils_abs
			END AS NUMERIC
		), 4
	) AS eosinophils_abs,
	neutrophils, -- impute bands/blasts?
	lymphocytes,
	monocytes,
	bands,
	basophils,
	eosinophils,
	atypical_lymphocytes,
	immature_granulocytes,
	metamyelocytes,
	nrbc,
	rbc,
	rdw,
	mch,
	mchc,
	hct,
	hgb,
	hgb_a1c,
	pla,
	crp,
	crp_hs
FROM blood_diff;