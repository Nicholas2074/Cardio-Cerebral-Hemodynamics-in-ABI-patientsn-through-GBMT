DROP TABLE IF EXISTS feat_day1_lab;
CREATE TABLE feat_day1_lab AS
/* -------------------------------------------------------------------------- */
-- all experimental indicators are maximized
/* -------------------------------------------------------------------------- */
-- //ANCHOR - repo_blood_diff
WITH repo_blood_diff AS (
	WITH tmp AS (
		SELECT tt.patientunitstayid,
			tt.wbc,
			tt.basos,
			tt.lymphs,
			tt.monos,
			tt.bands,
			tt.eos,
			tt.polys,
			tt.rbc,
			tt.rdw,
			tt.mch,
			tt.mchc,
			tt.hct,
			tt.hgb,
			tt.pla,
			tt.crp,
			tt.crp_hs
		FROM icu.patient pt
			INNER JOIN public.repo_blood_diff tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.chartoffset >= -1440
			AND tt.chartoffset <= 2880
	)
	SELECT patientunitstayid,
		MAX(wbc) AS wbc,
		MAX(polys) AS polys,
		MAX(lymphs) AS lymphs,
		MAX(monos) AS monos,
		MAX(bands) AS bands,
		MAX(basos) AS basos,
		MAX(eos) AS eos,
		MAX(rbc) AS rbc,
		MAX(rdw) AS rdw,
		MAX(mch) AS mch,
		MAX(mchc) AS mchc,
		MAX(hct) AS hct,
		MAX(hgb) AS hgb,
		MAX(pla) AS pla,
		MAX(crp) AS crp,
		MAX(crp_hs) AS crp_hs
	FROM tmp
	GROUP BY patientunitstayid
),
-- //ANCHOR - repo_chemistry
repo_chemistry AS (
	WITH tmp AS (
		SELECT tt.patientunitstayid,
			tt.glucose,
			tt.lac,
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
		FROM icu.patient pt
			INNER JOIN public.repo_chemistry tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.chartoffset >= -1440
			AND tt.chartoffset <= 2880
	)
	SELECT patientunitstayid,
		MAX(glucose) AS glucose,
		MAX(lac) AS lac,
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
	FROM tmp
	GROUP BY patientunitstayid
),
-- //ANCHOR - repo_bg
repo_bg AS (
	WITH tmp AS (
		SELECT tt.patientunitstayid,
			tt.ph,
			CASE
				WHEN fio2 IS NOT NULL THEN (tt.pao2 / tt.fio2)
				ELSE NULL
			END AS oi,
			tt.pao2,
			tt.paco2,
			tt.aniongap,
			tt.bicarbonate,
			tt.baseexcess,
			tt.peep
		FROM icu.patient pt
			INNER JOIN public.repo_bg tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.chartoffset >= -1440
			AND tt.chartoffset <= 2880
	)
	SELECT patientunitstayid,
		MAX(ph) AS ph,
		MAX(oi) AS oi,
		MAX(pao2) AS pao2,
		MAX(paco2) AS paco2,
		MAX(aniongap) AS aniongap,
		MAX(bicarbonate) AS bicarbonate,
		MAX(baseexcess) AS baseexcess,
		MAX(peep) AS peep
	FROM tmp
	GROUP BY patientunitstayid
),
-- //ANCHOR - repocoagulation
repo_coagulation AS (
	WITH tmp AS (
		SELECT tt.patientunitstayid,
			tt.inr,
			tt.pt,
			tt.ptt,
			tt.fibrinogen
		FROM icu.patient pt
			INNER JOIN public.repo_coagulation tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.chartoffset >= -1440
			AND tt.chartoffset <= 2880
	)
	SELECT patientunitstayid,
		MAX(inr) AS inr,
		MAX(pt) AS pt,
		MAX(ptt) AS ptt,
		MAX(fibrinogen) AS fibrinogen
	FROM tmp
	GROUP BY patientunitstayid
),
-- //ANCHOR - repo_cardiac
repo_cardiac AS (
	WITH tmp AS (
		SELECT tt.patientunitstayid,
			tt.cpk_mb,
			tt.cpk_mb_index,
			tt.cpk,
			tt.ctnt
		FROM icu.patient pt
			INNER JOIN public.repo_cardiac tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.chartoffset >= -1440
			AND tt.chartoffset <= 2880
	)
	SELECT patientunitstayid,
		MAX(cpk_mb) AS cpk_mb,
		MAX(cpk_mb_index) AS cpk_mb_index,
		MAX(cpk) AS cpk,
		MAX(ctnt) AS ctnt
	FROM tmp
	GROUP BY patientunitstayid
)
-- //ANCHOR - total
SELECT pt.patientunitstayid,
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
	t2.glucose,
	t2.lac,
	t2.alt,
	t2.ast,
	t2.alp,
	t2.tbil,
	t2.albumin,
	t2.total_protein,
	t2.creatinine,
	t2.bun,
	t2.aniongap,
	t2.bicarbonate,
	t2.sodium,
	t2.potassium,
	t2.calcium,
	t2.chloride,
	t2.magnesium,
    t3.ph,
    t3.oi,
    t3.pao2,
    t3.paco2,
    t3.aniongap AS aniongap_bg,
    t3.bicarbonate AS bicarbonate_bg,
    t3.baseexcess,
    t3.peep,
	t4.inr,
	t4.pt,
	t4.ptt,
	t4.fibrinogen,
    t5.cpk_mb,
    t5.cpk_mb_index,
    t5.cpk,
    t5.ctnt
FROM icu.patient pt
LEFT JOIN repo_blood_diff t1 ON pt.patientunitstayid = t1.patientunitstayid
LEFT JOIN repo_chemistry t2 ON pt.patientunitstayid = t2.patientunitstayid
LEFT JOIN repo_bg t3 ON pt.patientunitstayid = t3.patientunitstayid
LEFT JOIN repo_coagulation t4 ON pt.patientunitstayid = t4.patientunitstayid
LEFT JOIN repo_cardiac t5 ON pt.patientunitstayid = t5.patientunitstayid
ORDER BY pt.patientunitstayid;