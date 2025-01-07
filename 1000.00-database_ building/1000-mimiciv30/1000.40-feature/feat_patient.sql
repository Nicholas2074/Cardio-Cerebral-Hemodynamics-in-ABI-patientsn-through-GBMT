DROP TABLE IF EXISTS feat_patient;
CREATE TABLE feat_patient AS
WITH age AS (
	SELECT pt.stay_id,
		tt.age
	FROM icu.icustays pt
		INNER JOIN public.repo_age tt ON pt.hadm_id = tt.hadm_id
	WHERE tt.age IS NOT NULL
),
bmi AS (
	WITH wt AS (
		SELECT stay_id,
			weight
		FROM public.repo_weight
		WHERE weight_type = 'admit'
	),
	ht AS (
		SELECT stay_id,
			FIRST_VALUE(height) OVER (
				PARTITION BY stay_id
				ORDER BY charttime
			) AS height
		FROM public.repo_height
	)
	SELECT wt.stay_id,
		ROUND(
			wt.weight::NUMERIC * 100 * 100 / ht.height::NUMERIC / ht.height::NUMERIC,
			2
		) AS bmi
	FROM wt
		INNER JOIN ht ON wt.stay_id = ht.stay_id
),
pvt AS (
	SELECT t1.stay_id,
		t1.intime,
		t1.outtime,
		ROUND(t1.los * 24) AS icu_los_hours,
		t2.admittime,
		t2.dischtime,
		t2.race,
		CAST (
			ROUND(
				EXTRACT(
					EPOCH
					FROM (t2.dischtime - t2.admittime)
				) / 3600
			) AS INTEGER
		) AS hosp_los_hours,
		DATE_PART('day', (t2.deathtime - pt.intime)) AS death_day,
		t2.hospital_expire_flag,
		CASE
			WHEN t3.gender = 'M' THEN 0
			WHEN t3.gender = 'F' THEN 1
			ELSE NULL
		END AS gender,
		DATE_PART('day', (t3.dod - pt.intime)) AS dod_day
	FROM icu.icustays pt
		INNER JOIN icu.icustays t1 ON pt.stay_id = t1.stay_id
		INNER JOIN hosp.admissions t2 ON pt.hadm_id = t2.hadm_id
		INNER JOIN hosp.patients t3 ON pt.subject_id = t3.subject_id
	WHERE t3.gender IS NOT NULL
)
SELECT age.stay_id,
	ROUND(age.age) AS age,
	pvt.gender,
	bmi.bmi,
	pvt.race,
	pvt.intime,
	pvt.outtime,
	pvt.icu_los_hours,
	pvt.admittime,
	pvt.dischtime,
	pvt.hosp_los_hours,
	pvt.hospital_expire_flag AS hosp_mortality,
	pvt.death_day,
	pvt.dod_day
FROM age
	LEFT JOIN bmi ON age.stay_id = bmi.stay_id
	LEFT JOIN pvt ON age.stay_id = pvt.stay_id
ORDER BY age.stay_id;