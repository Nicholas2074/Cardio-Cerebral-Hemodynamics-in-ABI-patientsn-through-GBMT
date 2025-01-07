-- //STUB - pnaid_0

-- patients with pneumonia

DROP MATERIALIZED VIEW IF EXISTS pnaid_0;
CREATE MATERIALIZED VIEW pnaid_0 AS WITH vw1 AS (
	SELECT DISTINCT patientunitstayid
	FROM icu.diagnosis
	WHERE (
			SUBSTR(icd9code, 1, 3) IN ('507', 'J69')
		)
		OR (
			SUBSTR(icd9code, 1, 2) IN ('48', 'J1')
		)
),
/* ---------------------------- 1st icu admission --------------------------- */
vw2 AS (
	SELECT patientunitstayid,
		ROW_NUMBER() OVER (
			PARTITION BY patienthealthsystemstayid
			ORDER BY ABS(hospitaladmitoffset) ASC
		) AS pid,
		patienthealthsystemstayid
	FROM icu.patient
),
/* -------------------------------- age < 18 -------------------------------- */
vw3 AS (
	SELECT DISTINCT patientunitstayid,
		CASE
			WHEN age ILIKE '%> 89%' THEN 90.0
			WHEN age = '' THEN NULL
			ELSE age::NUMERIC
		END AS age
	FROM icu.patient
),
/* ----------------------------- icu stay < 24h ----------------------------- */
vw4 AS (
	SELECT DISTINCT patientunitstayid,
		unitdischargeoffset
	FROM icu.patient
)
SELECT vw1.patientunitstayid
FROM vw1
	INNER JOIN vw2 ON vw1.patientunitstayid = vw2.patientunitstayid
	INNER JOIN vw3 ON vw1.patientunitstayid = vw3.patientunitstayid
	INNER JOIN vw4 ON vw1.patientunitstayid = vw4.patientunitstayid
WHERE vw2.pid = 1
	AND vw3.age >= 16
	AND vw4.unitdischargeoffset >= 1440;