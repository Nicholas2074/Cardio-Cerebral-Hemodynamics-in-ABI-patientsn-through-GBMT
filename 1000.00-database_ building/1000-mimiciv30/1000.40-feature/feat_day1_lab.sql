DROP TABLE IF EXISTS feat_day1_lab;
CREATE TABLE feat_day1_lab AS
/* -------------------------------------------------------------------------- */
-- all experimental indicators are maximized
/* -------------------------------------------------------------------------- */
-- //ANCHOR - repo_blood_diff
WITH repo_blood_diff AS (
	WITH vw0 AS (
		SELECT pt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.wbc,
			tt.basophils,
			tt.eosinophils,
			tt.neutrophils,
			tt.lymphocytes,
			tt.monocytes,
			tt.bands,
			tt.rbc,
			tt.rdw,
			tt.mch,
			tt.mchc,
			tt.hct,
			tt.hgb,
			tt.pla,
			tt.crp,
			tt.crp_hs
		FROM icu.icustays pt
			INNER JOIN public.repo_blood_diff tt ON pt.subject_id = tt.subject_id
			AND pt.hadm_id = tt.hadm_id
	)
	SELECT stay_id,
		MAX(wbc) AS wbc,
		MAX(basophils) AS basos,
		MAX(eosinophils) AS eos,
		MAX(neutrophils) AS polys,
		MAX(lymphocytes) AS lymphs,
		MAX(monocytes) AS monos,
		MAX(bands) AS bands,
		MAX(rbc) AS rbc,
		MAX(rdw) AS rdw,
		MAX(mch) AS mch,
		MAX(mchc) AS mchc,
		MAX(hct) AS hct,
		MAX(hgb) AS hgb,
		MAX(pla) AS pla,
		MAX(crp) AS crp,
		MAX(crp_hs) AS crp_hs
	FROM vw0
	WHERE chartoffset >= -1440
		AND chartoffset <= 2880
	GROUP BY stay_id
),
-- //ANCHOR - repo_bg_1
repo_bg_1 AS (
	WITH vw0 AS (
		SELECT pt.stay_id,
			ROUND(
				EXTRACT(
					EPOCH
					FROM (tt.charttime - pt.intime)
				) / 60
			) AS chartoffset,
			tt.lactate
		FROM icu.icustays pt
			INNER JOIN public.repo_bg tt ON pt.subject_id = tt.subject_id
			AND pt.hadm_id = tt.hadm_id
	)
	SELECT stay_id,
		MAX(lactate) AS lac
	FROM vw0
	WHERE chartoffset >= -1440
		AND chartoffset <= 2880
	GROUP BY stay_id
),
-- //ANCHOR - repo_chemistry
repo_chemistry AS (
	WITH vw0 AS (
		SELECT pt.stay_id,
			ROUND(
				EXTRACT(
					EPOCH
					FROM (tt.charttime - pt.intime)
				) / 60
			) AS chartoffset,
			tt.glucose,
			-- no chemistry lactate in mimic
			tt.alt,
			tt.ast,
			tt.alp,
			tt.tbil,
			tt.albumin,
			tt.total_protein,
			tt.creatinine,
			tt.bun,
			tt.aniongap,
			tt.bicarbonate,
			tt.sodium,
			tt.potassium,
			tt.calcium,
			tt.chloride,
			tt.magnesium
		FROM icu.icustays pt
			INNER JOIN public.repo_chemistry tt ON pt.subject_id = tt.subject_id
			AND pt.hadm_id = tt.hadm_id
	)
	SELECT stay_id,
		MAX(glucose) AS glucose,
		-- no chemistry lactate in mimic
		MAX(alt) AS alt,
		MAX(ast) AS ast,
		MAX(alp) AS alp,
		MAX(tbil) AS tbil,
		MAX(albumin) AS albumin,
		MAX(total_protein) AS total_protein,
		MAX(creatinine) AS creatinine,
		MAX(bun) AS bun,
		MAX(aniongap) AS aniongap,
		MAX(bicarbonate) AS bicarbonate,
		MAX(sodium) AS sodium,
		MAX(potassium) AS potassium,
		MAX(calcium) AS calcium,
		MAX(chloride) AS chloride,
		MAX(magnesium) AS magnesium
	FROM vw0
	WHERE chartoffset >= -1440
		AND chartoffset <= 2880
	GROUP BY stay_id
),
-- //ANCHOR - repo_bg_2
repo_bg_2 AS (
	WITH vw0 AS (
		SELECT pt.stay_id,
			ROUND(
				EXTRACT(
					EPOCH
					FROM (tt.charttime - pt.intime)
				) / 60
			) AS chartoffset,
			tt.ph,
			tt.pao2fio2ratio,
			tt.pao2,
			tt.paco2,
			tt.aniongap,
			tt.bicarbonate,
			tt.baseexcess,
			tt.peep
		FROM icu.icustays pt
			INNER JOIN public.repo_bg tt ON pt.subject_id = tt.subject_id
			AND pt.hadm_id = tt.hadm_id
	)
	SELECT stay_id,
		MAX(ph) AS ph,
		MAX(pao2fio2ratio) AS oi,
		MAX(pao2) AS pao2,
		MAX(paco2) AS paco2,
		MAX(aniongap) AS aniongap,
		MAX(bicarbonate) AS bicarbonate,
		MAX(baseexcess) AS baseexcess,
		MAX(peep) AS peep
	FROM vw0
	WHERE chartoffset >= -1440
		AND chartoffset <= 2880
	GROUP BY stay_id
),
-- //ANCHOR - repo_coagulation
repo_coagulation AS (
	WITH vw0 AS (
		SELECT pt.stay_id,
			ROUND(
				EXTRACT(
					EPOCH
					FROM (tt.charttime - pt.intime)
				) / 60
			) AS chartoffset,
			tt.inr,
			tt.pt,
			tt.ptt,
			tt.fibrinogen
		FROM icu.icustays pt
			INNER JOIN public.repo_coagulation tt ON pt.subject_id = tt.subject_id
			AND pt.hadm_id = tt.hadm_id
	)
	SELECT stay_id,
		MAX(inr) AS inr,
		MAX(pt) AS pt,
		MAX(ptt) AS ptt,
		MAX(fibrinogen) AS fibrinogen
	FROM vw0
	WHERE chartoffset >= -1440
		AND chartoffset <= 2880
	GROUP BY stay_id
),
-- //ANCHOR - repo_cardiac
repo_cardiac AS (
	WITH vw0 AS (
		SELECT pt.stay_id,
			ROUND(
				EXTRACT(
					EPOCH
					FROM (tt.charttime - pt.intime)
				) / 60
			) AS chartoffset,
			tt.ck_mb,
			tt.ck_mb_index,
			tt.ck,
			tt.ctnt
		FROM icu.icustays pt
			INNER JOIN public.repo_cardiac tt ON pt.subject_id = tt.subject_id
			AND pt.hadm_id = tt.hadm_id
	)
	SELECT stay_id,
		MAX(ck_mb) AS cpk_mb,
		MAX(ck_mb_index) AS cpk_mb_index,
		MAX(ck) AS cpk,
		MAX(ctnt) AS ctnt
	FROM vw0
	WHERE chartoffset >= -1440
		AND chartoffset <= 2880
	GROUP BY stay_id
)
-- //ANCHOR - total
SELECT pt.stay_id,
	t1.wbc,
	t1.polys,
	t1.lymphs,
	t1.monos,
	t1.bands,
	t1.basos,
	t1.eos,
	t1.rbc,
	t1.rdw,
	t1.mch,
	t1.mchc,
	t1.hct,
	t1.hgb,
	t1.pla,
	t1.crp,
	t1.crp_hs,
	t2.lac,
	t3.glucose,
	t3.alt,
	t3.ast,
	t3.alp,
	t3.tbil,
	t3.albumin,
	t3.total_protein,
	t3.creatinine,
	t3.bun,
	t3.aniongap,
	t3.bicarbonate,
	t3.sodium,
	t3.potassium,
	t3.calcium,
	t3.chloride,
	t3.magnesium,
	t4.ph,
	t4.oi,
	t4.pao2,
	t4.paco2,
	t4.aniongap AS aniongap_bg,
	t4.bicarbonate AS bicarbonate_bg,
	t4.baseexcess,
	t4.peep,
	t5.inr,
	t5.pt,
	t5.ptt,
	t5.fibrinogen,
	t6.cpk_mb,
	t6.cpk_mb_index,
	t6.cpk,
	t6.ctnt
FROM icu.icustays pt
	LEFT JOIN repo_blood_diff t1 ON pt.stay_id = t1.stay_id
	LEFT JOIN repo_bg_1 t2 ON pt.stay_id = t2.stay_id
	LEFT JOIN repo_chemistry t3 ON pt.stay_id = t3.stay_id
	LEFT JOIN repo_bg_2 t4 ON pt.stay_id = t4.stay_id
	LEFT JOIN repo_coagulation t5 ON pt.stay_id = t5.stay_id
	LEFT JOIN repo_cardiac t6 ON pt.stay_id = t6.stay_id
ORDER BY pt.stay_id;