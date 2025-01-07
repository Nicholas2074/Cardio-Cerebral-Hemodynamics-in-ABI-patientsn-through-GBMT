DROP TABLE IF EXISTS feat_day1_score;
CREATE TABLE feat_day1_score AS
-- //ANCHOR - day1_gcs
WITH day1_gcs AS (
	WITH vw0 AS (
		SELECT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			tt.gcs_eyes AS eyes,
			tt.gcs_verbal AS verbal,
			tt.gcs_motor AS motor,
			tt.gcs
		FROM icu.icustays pt
			INNER JOIN public.repo_gcs tt ON pt.stay_id = tt.stay_id
		WHERE gcs > 0
	)
	SELECT stay_id,
		MIN(eyes) AS eyes,
		MIN(verbal) AS verbal,
		MIN(motor) AS motor,
		MIN(gcs) AS gcs
	FROM vw0
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
),
-- //ANCHOR - day1_sofa
day1_sofa AS (
	SELECT pt.stay_id,
		MAX(tt.sofa) AS sofa
	FROM icu.icustays pt
		INNER JOIN public.repo_day1_sofa tt ON pt.stay_id = tt.stay_id
	GROUP BY pt.stay_id
),
-- //ANCHOR - day1_charlson
day1_charlson AS (
	SELECT pt.stay_id,
		MAX(tt.charlson) AS charlson
	FROM icu.icustays pt
		INNER JOIN public.repo_charlson tt ON pt.hadm_id = tt.hadm_id
	GROUP BY pt.stay_id
),
-- //ANCHOR - day1_delirium
day1_delirium AS (
	WITH delirium AS (
		SELECT tt.stay_id,
			CAST(
				ROUND(
					EXTRACT(
						EPOCH
						FROM (tt.charttime - pt.intime)
					) / 60
				) AS INTEGER
			) AS chartoffset,
			--  to make sure the portability of the code
			CASE
				WHEN tt.value = 'Positive' THEN 1
				WHEN tt.value = 'Negative' THEN 0
				WHEN tt.value = 'UTA' THEN NULL -- uta means 'unbale to assess'
				ELSE NULL
			END AS delirium
		FROM icu.icustays pt
			INNER JOIN icu.chartevents tt ON pt.stay_id = tt.stay_id
		WHERE tt.itemid = '228332' -- 228332 category: pain/sedation
			-- 228688 category: md progress note
			AND tt.value IS NOT NULL
	)
	SELECT stay_id,
		MAX(delirium) AS delirium
	FROM delirium
	WHERE chartoffset >= 0
		AND chartoffset <= 1440
	GROUP BY stay_id
)
-- //ANCHOR - total
SELECT pt.stay_id,
	t1.eyes,
	t1.verbal,
	t1.motor,
	t1.gcs,
	t2.sofa,
	t3.charlson,
	t4.delirium
FROM icu.icustays pt
	LEFT JOIN day1_gcs t1 ON pt.stay_id = t1.stay_id
	LEFT JOIN day1_sofa t2 ON pt.stay_id = t2.stay_id
	LEFT JOIN day1_charlson t3 ON pt.stay_id = t3.stay_id
	LEFT JOIN day1_delirium t4 ON pt.stay_id = t4.stay_id
ORDER BY pt.stay_id;