DROP TABLE IF EXISTS feat_surgery;
CREATE TABLE feat_surgery AS
-- //ANCHOR - craniotomy
--  if a column has time as the suffix
--  e.g. charttime, then the data resolution is down to the minute
--  if the column has date as the suffix, e.g. chartdate
--  then the data resolution is down to the day
--  that means that measurements in a chartdate column will always have 00:00:00 has the hour, minute, and second values
--  this does not mean it was recorded at midnight
--  it indicates that we do not have the exact time, only the date
WITH craniotomy AS (
	WITH t0 AS (
		SELECT DISTINCT t2.hadm_id,
			t2.chartdate,
			t2.icd_code,
			t1.long_title
		FROM hosp.d_icd_procedures t1
			INNER JOIN hosp.procedures_icd t2 ON t1.icd_code = t2.icd_code
	)
	SELECT pt.stay_id,
		DATE_PART('day', (t0.chartdate - pt.intime)) AS craniotomy_day,
		CASE
			WHEN SUBSTR(icd_code, 1, 4) IN ('0123', '0124', '0125') THEN 1
			ELSE 0
		END AS craniotomy,
		t0.icd_code,
		t0.long_title -- for double check
	FROM t0
		INNER JOIN icu.icustays pt ON t0.hadm_id = pt.hadm_id
	WHERE SUBSTR(icd_code, 1, 4) IN ('0123', '0124', '0125')
),
-- //ANCHOR - ventriculostomy
ventriculostomy AS (
	WITH t0 AS (
		SELECT DISTINCT t2.hadm_id,
			t2.chartdate,
			t2.icd_code,
			t1.long_title
		FROM hosp.d_icd_procedures t1
			INNER JOIN hosp.procedures_icd t2 ON t1.icd_code = t2.icd_code
	)
	SELECT pt.stay_id,
		DATE_PART('day', (t0.chartdate - pt.intime)) AS ventriculostomy_day,
		CASE
			WHEN SUBSTR(icd_code, 1, 3) IN ('022')
			OR SUBSTR(icd_code, 1, 4) IN ('1607', '1637', '1647')
			OR SUBSTR(icd_code, 1, 5) IN ('00160', '00163', '00164') THEN 1
			ELSE 0
		END AS ventriculostomy,
		t0.icd_code,
		t0.long_title -- for double check
	FROM t0
		INNER JOIN icu.icustays pt ON t0.hadm_id = pt.hadm_id
	WHERE SUBSTR(icd_code, 1, 3) IN ('022')
		OR SUBSTR(icd_code, 1, 4) IN ('1607', '1637', '1647')
		OR SUBSTR(icd_code, 1, 5) IN ('00160', '00163', '00164')
),
-- //ANCHOR - csfdrainage
csfdrainage AS (
	WITH t0 AS (
		SELECT DISTINCT t2.hadm_id,
			t2.chartdate,
			t2.icd_code,
			t1.long_title
		FROM hosp.d_icd_procedures t1
			INNER JOIN hosp.procedures_icd t2 ON t1.icd_code = t2.icd_code
	)
	SELECT pt.stay_id,
		DATE_PART('day', (t0.chartdate - pt.intime)) AS csfdrainage_day,
		CASE
			WHEN SUBSTR(icd_code, 1, 3) IN ('0220')
			OR SUBSTR(icd_code, 1, 5) IN ('00900', '00903', '00904')
			OR SUBSTR(icd_code, 1, 5) IN ('00960', '00963', '00964') THEN 1
			ELSE 0
		END AS csfdrainage,
		t0.icd_code,
		t0.long_title -- for double check
	FROM t0
		INNER JOIN icu.icustays pt ON t0.hadm_id = pt.hadm_id
	WHERE SUBSTR(icd_code, 1, 3) IN ('0220')
		OR SUBSTR(icd_code, 1, 5) IN ('00900', '00903', '00904')
		OR SUBSTR(icd_code, 1, 5) IN ('00960', '00963', '00964')
)
SELECT pt.stay_id,
	t1.craniotomy_day,
	t1.craniotomy,
	t2.ventriculostomy_day,
	t2.ventriculostomy,
	t3.csfdrainage_day,
	t3.csfdrainage
FROM icu.icustays pt
LEFT JOIN craniotomy t1 ON pt.stay_id = t1.stay_id
LEFT JOIN ventriculostomy t2 ON pt.stay_id = t2.stay_id
LEFT JOIN csfdrainage t3 ON pt.stay_id = t3.stay_id
ORDER BY pt.stay_id;