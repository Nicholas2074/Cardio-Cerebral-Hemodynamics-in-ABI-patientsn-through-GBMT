DROP TABLE IF EXISTS dmin_gcs;
CREATE TABLE dmin_gcs AS
WITH vw2 AS (
	WITH vw1 AS (
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
			chartoffset,
			MIN(eyes) AS eyes,
			MIN(verbal) AS verbal,
			MIN(motor) AS motor,
			MIN(gcs) AS gcs
		FROM vw0
		GROUP BY stay_id,
			chartoffset
	)
	SELECT stay_id,
		chartoffset,
		FIRST_VALUE(chartoffset) OVER (
			PARTITION BY stay_id 
			ORDER BY chartoffset ASC
		) AS adm_time,
		LAST_VALUE(chartoffset) OVER (
			PARTITION BY stay_id 
			ORDER BY chartoffset ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) AS dis_time,
		eyes,
		verbal,
		motor,
		gcs
	FROM vw1
)
SELECT DISTINCT stay_id,
	chartoffset,
	eyes::NUMERIC,
	verbal::NUMERIC,
	motor::NUMERIC,
	ROUND(gcs::NUMERIC) AS gcs,
	CASE
		WHEN chartoffset = adm_time THEN gcs
		ELSE NULL
	END AS adm_gcs,
	CASE
		WHEN chartoffset = dis_time THEN gcs
		ELSE NULL
	END AS dis_gcs
FROM vw2
ORDER BY stay_id,
	chartoffset;