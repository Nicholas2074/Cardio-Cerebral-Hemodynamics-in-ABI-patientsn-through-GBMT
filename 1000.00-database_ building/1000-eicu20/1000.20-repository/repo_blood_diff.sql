DROP TABLE IF EXISTS repo_blood_diff;
CREATE TABLE repo_blood_diff AS -- remove duplicate labs if they exist at the same time
WITH vw0 AS (
	SELECT patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	FROM icu.lab
	WHERE labname in (
		'WBC x 1000', -- labtypeid = 3, K/mcL
		'-polys', -- labtypeid = 3, %
		'-lymphs', --labtypeid = 3, %
		'-monos', -- labtypeid = 3, %
		'-bands', -- labtypeid = 3, %, band neutrophil
		'-basos', -- labtypeid = 3, %
		'-eos', -- labtypeid = 3, %
		-- lose imm_granulocytes
		-- lose atypical_lymphocytes
		'RBC', -- labtypeid = 3, M/mcL(mil/mcL), only have labname of 'RBC'
		'RDW', -- labtypeid = 3, %
		-- lose rdw-sd
		'MCH', -- labtypeid = 3, g/dL
		'MCHC', -- labtypeid = 3, g/dL
		'Hct',
		'Hgb',
		'platelets x 1000', -- labtypeid = 3, K/mcL and K/uL
		'CRP', -- labtypeid = 4, mg/dL
		'CRP-hs' -- labtypeid = 4, mg/L
		)
		-- 1 for chemistry, 2 for drug level, 3 for hemo, 4 for misc, 5 for non-mapped, 6 for sensitive, 7 for ABG lab
	GROUP BY patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	HAVING COUNT(DISTINCT labresult) <= 1
), -- get the last lab to be revised
vw1 AS (
	SELECT tt.patientunitstayid,
		tt.labname,
		tt.labresultoffset,
		tt.labresultrevisedoffset,
		tt.labresult,
		ROW_NUMBER() OVER (
			PARTITION BY tt.patientunitstayid,
			tt.labname,
			tt.labresultoffset
			ORDER BY tt.labresultrevisedoffset DESC
		) AS rn
	FROM icu.lab tt
		INNER JOIN vw0 ON tt.patientunitstayid = vw0.patientunitstayid
		AND tt.labname = vw0.labname
		AND tt.labresultoffset = vw0.labresultoffset
		AND tt.labresultrevisedoffset = vw0.labresultrevisedoffset 
	-- only valid lab values
	WHERE	(
			tt.labname = 'WBC x 1000'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = '-polys'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = '-lymphs'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = '-monos'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = '-bands'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = '-basos'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = '-eos'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'RBC'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'RDW'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'MCH'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'MCHC'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'Hct'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'Hgb'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'platelets x 1000'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'CRP'
			AND tt.labresult > 0
		)
		OR (
			tt.labname = 'CRP-hs'
			AND tt.labresult > 0
		)
)
SELECT patientunitstayid,
	labresultoffset AS chartoffset,
	MAX(
		CASE
			WHEN labname = 'WBC x 1000' THEN labresult
			ELSE NULL
		END
	) AS wbc,
	MAX(
		CASE
			WHEN labname = '-polys' THEN labresult
			ELSE NULL
		END
	) AS polys,
	MAX(
		CASE
			WHEN labname = '-lymphs' THEN labresult
			ELSE NULL
		END
	) AS lymphs,
	MAX(
		CASE
			WHEN labname = '-monos' THEN labresult
			ELSE NULL
		END
	) AS monos,
	MAX(
		CASE
			WHEN labname = '-bands' THEN labresult
			ELSE NULL
		END
	) AS bands,
	MAX(
		CASE
			WHEN labname = '-basos' THEN labresult
			ELSE NULL
		END
	) AS basos,
	MAX(
		CASE
			WHEN labname = '-eos' THEN labresult
			ELSE NULL
		END
	) AS eos,
	MAX(
		CASE
			WHEN labname = 'RBC' THEN labresult
			ELSE NULL
		END
	) AS rbc,
	MAX(
		CASE
			WHEN labname = 'RDW' THEN labresult
			ELSE NULL
		END
	) AS rdw,
	MAX(
		CASE
			WHEN labname = 'MCH' THEN labresult
			ELSE NULL
		END
	) AS mch,
	MAX(
		CASE
			WHEN labname = 'MCHC' THEN labresult
			ELSE NULL
		END
	) AS mchc,
	MAX(
		CASE
			WHEN labname = 'Hct' THEN labresult
			ELSE NULL
		END
	) AS hct,
	MAX(
		CASE
			WHEN labname = 'Hgb' THEN labresult
			ELSE NULL
		END
	) AS hgb,
	MAX(
		CASE
			WHEN labname = 'platelets x 1000' THEN labresult
			ELSE NULL
		END
	) AS pla,
	MAX(
		CASE
			WHEN labname = 'CRP' THEN labresult
			ELSE NULL
		END
	) AS crp,
	MAX(
		CASE
			WHEN labname = 'CRP-hs' THEN labresult
			ELSE NULL
		END
	) AS crp_hs
FROM vw1
WHERE rn = 1
GROUP BY patientunitstayid,
	labresultoffset
ORDER BY patientunitstayid,
	labresultoffset;