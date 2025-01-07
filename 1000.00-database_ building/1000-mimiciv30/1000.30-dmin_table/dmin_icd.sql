DROP TABLE IF EXISTS dmin_icd;
CREATE TABLE dmin_icd AS
WITH vw0 AS (
	SELECT tt.*
	FROM icu.icustays pt
		INNER JOIN hosp.diagnoses_icd tt ON pt.subject_id = tt.subject_id
		AND pt.hadm_id = tt.hadm_id
)
SELECT t1.subject_id,
	t1.hadm_id,
	t1.seq_num,
	t1.icd_code,
	t1.icd_version,
	t2.long_title
FROM vw0 t1
	INNER JOIN hosp.d_icd_diagnoses t2 ON t1.icd_code = t2.icd_code
	AND t1.icd_version = t2.icd_version;