DROP TABLE IF EXISTS dmin_gcs;
CREATE TABLE dmin_gcs AS
WITH vw2 AS (
	WITH vw1 AS (
		WITH vw0 AS (
			WITH nurse AS (
				SELECT DISTINCT tt.patientunitstayid,
					tt.chartoffset,
					tt.gcs,
					tt.gcs_eyes AS eyes,
					tt.gcs_verbal AS verbal,
					tt.gcs_motor AS motor
					-- tt.gcs_unable,
					-- tt.gcs_intub,
					-- tt.delirium_scale, -- icu.physicalexam dosen't contain delirium score
					-- tt.delirium_score
				FROM icu.patient pt
					INNER JOIN public.repo_score tt
					ON pt.patientunitstayid = tt.patientunitstayid
				WHERE tt.gcs > 0
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
					t0.physicalexamoffset AS chartoffset,
					t0.gcs,
					t0.eyes,
					t0.verbal,
					t0.motor
				FROM icu.patient pt
					INNER JOIN t0 ON pt.patientunitstayid = t0.patientunitstayid
				WHERE t0.gcs > 0
			)
			SELECT patientunitstayid,
				chartoffset,
				eyes,
				verbal,
				motor,
				gcs
			FROM nurse
			UNION
			SELECT patientunitstayid,
				chartoffset,
				eyes,
				verbal,
				motor,
				gcs
			FROM physic
		)
		SELECT patientunitstayid,
			chartoffset,
			MIN(eyes) AS eyes,
			MIN(verbal) AS verbal,
			MIN(motor) AS motor,
			ROUND(MIN(gcs)) AS gcs
		FROM vw0
		GROUP BY patientunitstayid,
			chartoffset
	)
	SELECT patientunitstayid,
		chartoffset,
		FIRST_VALUE(chartoffset) OVER (
			PARTITION BY patientunitstayid
			ORDER BY chartoffset ASC
		) AS adm_time,
		LAST_VALUE(chartoffset) OVER (
			PARTITION BY patientunitstayid
			ORDER BY chartoffset ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) AS dis_time,
		eyes,
		verbal,
		motor,
		gcs
	FROM vw1
)
SELECT DISTINCT patientunitstayid,
	chartoffset,
	eyes::NUMERIC,
	verbal::NUMERIC,
	motor::NUMERIC,
	gcs::NUMERIC,
	CASE
		WHEN chartoffset = adm_time THEN gcs
		ELSE NULL
	END AS adm_gcs,
	CASE
		WHEN chartoffset = dis_time THEN gcs
		ELSE NULL
	END AS dis_gcs
FROM vw2
ORDER BY patientunitstayid,
	chartoffset;