DROP TABLE IF EXISTS feat_surgery;
CREATE TABLE feat_surgery AS
-- //ANCHOR - craniotomy
WITH craniotomy AS (
	SELECT DISTINCT tt.patientunitstayid,
		MIN(tt.treatmentoffset / 60 * 24) AS craniotomy_day,
		-- 1 = yes
		-- 0 = no
		MAX(CASE
			WHEN tt.treatmentstring ILIKE '%surgery%'
			AND tt.treatmentstring ILIKE '%craniotomy%' THEN 1
			ELSE 0
		END) AS craniotomy,
		MAX(CASE
			WHEN tt.activeupondischarge = 'TRUE' THEN 1
			WHEN tt.activeupondischarge = 'FALSE' THEN 0
			ELSE 0
		END) AS craniotomy_aud
	FROM icu.patient pt
		INNER JOIN icu.treatment tt ON pt.patientunitstayid = tt.patientunitstayid
	WHERE treatmentstring ILIKE '%surgery%'
		AND treatmentstring ILIKE '%craniotomy%'
	GROUP BY tt.patientunitstayid
	ORDER BY tt.patientunitstayid
),
-- //ANCHOR - ventriculostomy
ventriculostomy AS (
	SELECT DISTINCT tt.patientunitstayid,
		MIN(tt.treatmentoffset / 60 * 24) AS ventriculostomy_day,
		-- 1 = yes
		-- 0 = no
		MAX(CASE
			WHEN treatmentstring ILIKE '%ventriculostomy%' THEN 1
			ELSE 0
		END) AS ventriculostomy,
		MAX(CASE
			WHEN tt.activeupondischarge = 'TRUE' THEN 1
			WHEN tt.activeupondischarge = 'FALSE' THEN 0
			ELSE 0
		END) AS ventriculostomy_aud
	FROM icu.patient pt
		INNER JOIN icu.treatment tt ON pt.patientunitstayid = tt.patientunitstayid
	WHERE treatmentstring ILIKE '%ventriculostomy%'
	GROUP BY tt.patientunitstayid
	ORDER BY tt.patientunitstayid
),
-- //ANCHOR - csfdrainage
csfdrainage AS (
	SELECT DISTINCT tt.patientunitstayid,
		MIN(tt.treatmentoffset / 60) AS csfdrainage_day,
		-- 1 = yes
		-- 0 = no
		MAX(CASE
			WHEN treatmentstring ILIKE '%csf%drainage%' THEN 1
			ELSE 0
		END) AS csfdrainage,
		MAX(CASE
			WHEN tt.activeupondischarge = 'TRUE' THEN 1
			WHEN tt.activeupondischarge = 'FALSE' THEN 0
			ELSE 0
		END) AS csfdrainage_aud
	FROM icu.patient pt
		INNER JOIN icu.treatment tt ON pt.patientunitstayid = tt.patientunitstayid
	WHERE treatmentstring ILIKE '%csf%drainage%'
	GROUP BY tt.patientunitstayid
	ORDER BY tt.patientunitstayid
)
SELECT DISTINCT pt.patientunitstayid,
	t1.craniotomy_day,
	t1.craniotomy,
	-- t1.craniotomy_aud,
	t2.ventriculostomy_day,
	t2.ventriculostomy,
	-- t2.ventriculostomy_aud,
	t3.csfdrainage_day,
	t3.csfdrainage
	-- t3.csfdrainage_aud
FROM icu.patient pt
	LEFT JOIN craniotomy t1 ON pt.patientunitstayid = t1.patientunitstayid
	LEFT JOIN ventriculostomy t2 ON pt.patientunitstayid = t2.patientunitstayid
	LEFT JOIN csfdrainage t3 ON pt.patientunitstayid = t3.patientunitstayid
ORDER BY pt.patientunitstayid;