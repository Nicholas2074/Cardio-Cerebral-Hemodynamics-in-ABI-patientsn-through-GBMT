DROP TABLE IF EXISTS feat_patient;
CREATE TABLE feat_patient AS
WITH vw0 AS (
	SELECT DISTINCT patientunitstayid,
		CASE
			WHEN age ILIKE '%> 89%' THEN 90.0
			WHEN age = '' THEN NULL
			ELSE age::NUMERIC
		END AS age,
		CASE
			WHEN gender = 'Male' THEN 0
			WHEN gender = 'Female' THEN 1
			ELSE NULL
		END AS gender,
		ethnicity,
		apacheadmissiondx,
		(unitdischargeoffset / 60) AS icu_los_hours,
		hospitaladmitoffset,
		hospitaldischargeoffset,
		(
			(hospitaldischargeoffset - hospitaladmitoffset) / 60
		) AS hosp_los_hours,
		CASE
			WHEN hospitaldischargestatus = 'Alive' THEN 0
			WHEN hospitaldischargestatus = 'Expired' THEN 1
			ELSE NULL
		END AS hosp_mortality
	FROM icu.patient
),
vw1 AS (
	SELECT DISTINCT pt.patientunitstayid,
		CASE
			WHEN pt.admissionheight <> 0 THEN (
				tt.weight * 100 * 100 / (pt.admissionheight * pt.admissionheight)
			)
			ELSE NULL
		END AS bmi
	FROM icu.patient pt
		INNER JOIN public.repo_weight tt ON pt.patientunitstayid = tt.patientunitstayid
	WHERE weight_type = 'admit'
)
SELECT DISTINCT vw0.patientunitstayid,
	ROUND(vw0.age) AS age,
	vw0.gender,
	ROUND(vw1.bmi) AS bmi,
	vw0.ethnicity AS race,
	vw0.apacheadmissiondx,
	vw0.icu_los_hours,
	vw0.hospitaladmitoffset,
	vw0.hospitaldischargeoffset,
	vw0.hosp_los_hours,
	vw0.hosp_mortality
FROM vw0
LEFT JOIN vw1 ON vw0.patientunitstayid = vw1.patientunitstayid
ORDER BY vw0.patientunitstayid;