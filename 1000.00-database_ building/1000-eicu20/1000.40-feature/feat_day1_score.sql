DROP TABLE IF EXISTS feat_day1_score;
CREATE TABLE feat_day1_score AS
WITH day1_gcs AS (
	WITH gcs AS (
		WITH nurse AS (
			SELECT DISTINCT tt.patientunitstayid,
				tt.gcs,
				tt.gcs_eyes AS eyes,
				tt.gcs_verbal AS verbal,
				tt.gcs_motor AS motor -- tt.gcs_unable,
				-- tt.gcs_intub
			FROM icu.patient pt -- repo_gcs from icu.nursecharting
				INNER JOIN public.repo_score tt ON pt.patientunitstayid = tt.patientunitstayid
			WHERE tt.gcs > 0
				AND tt.chartoffset >= 0
				AND tt.chartoffset <= 1440
		),
		physic AS (
			WITH t0 AS (
				WITH t1 AS (
					SELECT patientunitstayid,
						physicalexamoffset,
						physicalexamvalue::NUMERIC AS eyes
					FROM icu.physicalexam
					WHERE physicalexampath ILIKE '%neurologic/gcs/eyes%'
				),
				t2 AS (
					SELECT patientunitstayid,
						physicalexamoffset,
						physicalexamvalue::NUMERIC AS verbal
					FROM icu.physicalexam
					WHERE physicalexampath ILIKE '%neurologic/gcs/verbal%'
				),
				t3 AS (
					SELECT patientunitstayid,
						physicalexamoffset,
						physicalexamvalue::NUMERIC AS motor
					FROM icu.physicalexam
					WHERE physicalexampath ILIKE '%neurologic/gcs/motor%'
				)
				SELECT DISTINCT t1.patientunitstayid,
					t1.physicalexamoffset,
					(t1.eyes + t2.verbal + t3.motor) AS gcs,
					t1.eyes,
					t2.verbal,
					t3.motor
				FROM t1
					INNER JOIN t2 ON t1.patientunitstayid = t2.patientunitstayid
					AND t1.physicalexamoffset = t2.physicalexamoffset
					INNER JOIN t3 ON t1.patientunitstayid = t3.patientunitstayid
					AND t1.physicalexamoffset = t3.physicalexamoffset
				ORDER BY t1.patientunitstayid,
					t1.physicalexamoffset
			)
			SELECT DISTINCT pt.patientunitstayid,
				tt.gcs,
				tt.eyes,
				tt.verbal,
				tt.motor
			FROM icu.patient pt
				INNER JOIN t0 tt ON pt.patientunitstayid = tt.patientunitstayid
			WHERE tt.gcs > 0
				AND tt.physicalexamoffset >= 0
				AND tt.physicalexamoffset <= 1440
		)
		SELECT patientunitstayid,
			eyes,
			verbal,
			motor,
			gcs
		FROM nurse
		UNION
		SELECT patientunitstayid,
			eyes,
			verbal,
			motor,
			gcs
		FROM physic
	)
	SELECT DISTINCT patientunitstayid,
		MIN(eyes::NUMERIC) AS eyes,
		MIN(verbal::NUMERIC) AS verbal,
		MIN(motor::NUMERIC) AS motor,
		ROUND(MIN(gcs::NUMERIC)) AS gcs
		FROM gcs
	GROUP BY patientunitstayid
),
-- //ANCHOR - day1_sofa
day1_sofa AS (
	SELECT DISTINCT pt.patientunitstayid,
		MAX(tt.sofa) AS sofa
	FROM icu.patient pt
		INNER JOIN public.repo_day1_sofa tt ON pt.patientunitstayid = tt.patientunitstayid
	GROUP BY pt.patientunitstayid
		-- sofa originally called firstday_sofa
),
-- //ANCHOR - day1_charlson
day1_charlson AS (
	SELECT DISTINCT pt.patientunitstayid,
		MAX(tt.charlson) AS charlson
	FROM icu.patient pt
		INNER JOIN public.repo_charlson tt ON pt.patientunitstayid = tt.patientunitstayid
	GROUP BY pt.patientunitstayid
),
-- //ANCHOR - day1_delirium
day1_delirium AS (
	WITH t0 AS (
		SELECT DISTINCT pt.patientunitstayid,
			tt.delirium_score AS delirium -- icu.physicalexam dosen't contain delirium score
		FROM icu.patient pt
			INNER JOIN public.repo_score tt ON pt.patientunitstayid = tt.patientunitstayid
		WHERE tt.gcs > 0
			AND tt.chartoffset >= 0
			AND tt.chartoffset <= 1440
	)
	SELECT patientunitstayid,
		ROUND(MAX(delirium)) AS delirium
	FROM t0
	GROUP BY patientunitstayid
)
SELECT pt.patientunitstayid,
	t1.eyes,
	t1.verbal,
	t1.motor,
	t1.gcs,
	t2.sofa,
	t3.charlson,
	CASE
		WHEN t4.delirium >= 1 THEN 1
		WHEN t4.delirium = 0 THEN 0
		ELSE NULL
	END AS delirium
FROM icu.patient pt
	LEFT JOIN day1_gcs t1 on pt.patientunitstayid = t1.patientunitstayid
	LEFT JOIN day1_sofa t2 ON pt.patientunitstayid = t2.patientunitstayid
	LEFT JOIN day1_charlson t3 ON pt.patientunitstayid = t3.patientunitstayid
	LEFT JOIN day1_delirium t4 ON pt.patientunitstayid = t4.patientunitstayid
ORDER BY pt.patientunitstayid;