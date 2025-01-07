DROP TABLE IF EXISTS feat_diagnosis;
CREATE TABLE feat_diagnosis AS
-- //ANCHOR - hypertension
WITH diag AS (
	SELECT hadm_id,
		CASE
			WHEN icd_version = 9 THEN icd_code
			ELSE NULL
		END AS icd9_code,
		CASE
			WHEN icd_version = 10 THEN icd_code
			ELSE NULL
		END AS icd10_code
	FROM hosp.diagnoses_icd
),
vw1 AS (
	SELECT pt.hadm_id,
		MAX(
			CASE
				WHEN SUBSTR(icd9_code, 1, 3) = '401'
				OR SUBSTR(icd10_code, 1, 3) = 'I10' THEN 1
				ELSE 0
			END
		) AS hypertension
	FROM hosp.admissions pt
		LEFT JOIN diag ON pt.hadm_id = diag.hadm_id
	GROUP BY pt.hadm_id
),
-- //ANCHOR - repo_charlson
vw2 AS (
SELECT hadm_id,
	CASE
		WHEN cerebrovascular_disease > 0 THEN 1
		ELSE 0
	END AS cerebrovascular_disease,
	CASE
		WHEN paraplegia > 0 THEN 1
		ELSE 0
	END AS paraplegia,
	CASE
		WHEN dementia > 0 THEN 1
		ELSE 0
	END AS dementia,
	CASE
		WHEN myocardial_infarct > 0 THEN 1
		ELSE 0
	END AS myocardial_infarct,
	CASE
		WHEN congestive_heart_failure > 0 THEN 1
		ELSE 0
	END AS congestive_heart_failure,
	CASE
		WHEN peripheral_vascular_disease > 0 THEN 1
		ELSE 0
	END AS peripheral_vascular_disease,
	CASE
		WHEN chronic_pulmonary_disease > 0 THEN 1
		ELSE 0
	END AS chronic_pulmonary_disease,
	CASE
		WHEN rheumatic_disease > 0 THEN 1
		ELSE 0
	END AS rheumatic_disease,
	CASE
		WHEN peptic_ulcer_disease > 0 THEN 1
		ELSE 0
	END AS peptic_ulcer_disease,
	CASE
		WHEN mild_liver_disease > 0 THEN 1
		ELSE 0
	END AS mild_liver_disease,
	CASE
		WHEN severe_liver_disease > 0 THEN 1
		ELSE 0
	END AS severe_liver_disease,
	CASE
		WHEN renal_disease > 0 THEN 1
		ELSE 0
	END AS renal_disease,
	CASE
		WHEN diabetes > 0 THEN 1
		ELSE 0
	END AS diabetes,
	CASE
		WHEN malignant_cancer > 0 THEN 1
		ELSE 0
	END AS malignant_cancer,
	CASE
		WHEN metastatic_solid_tumor > 0  THEN 1
		ELSE 0
	END AS metastatic_solid_tumor,
	CASE
		WHEN aids > 0 THEN 1
		ELSE 0
	END AS aids
FROM public.repo_charlson
)
SELECT pt.stay_id,
    MAX(vw1.hypertension) AS hypertension,
    MAX(vw2.cerebrovascular_disease) AS cerebrovascular_disease,
    MAX(vw2.paraplegia) AS paraplegia,
    MAX(vw2.dementia) AS dementia,
    MAX(vw2.myocardial_infarct) AS myocardial_infarct,
    MAX(vw2.congestive_heart_failure) AS congestive_heart_failure,
    MAX(vw2.peripheral_vascular_disease) AS peripheral_vascular_disease,
    MAX(vw2.chronic_pulmonary_disease) AS chronic_pulmonary_disease,
    MAX(vw2.rheumatic_disease) AS rheumatic_disease,
    MAX(vw2.peptic_ulcer_disease) AS peptic_ulcer_disease,
    MAX(vw2.mild_liver_disease) AS mild_liver_disease,
    MAX(vw2.severe_liver_disease) AS severe_liver_disease,
    MAX(vw2.renal_disease) AS renal_disease,
    MAX(vw2.diabetes) AS diabetes,
    MAX(vw2.malignant_cancer) AS malignant_cancer,
    MAX(vw2.metastatic_solid_tumor) AS metastatic_solid_tumor,
    MAX(vw2.aids) AS aids
FROM icu.icustays pt
LEFT JOIN vw1 ON pt.hadm_id = vw1.hadm_id
LEFT JOIN vw2 ON pt.hadm_id = vw2.hadm_id
GROUP BY pt.stay_id
ORDER BY pt.stay_id;