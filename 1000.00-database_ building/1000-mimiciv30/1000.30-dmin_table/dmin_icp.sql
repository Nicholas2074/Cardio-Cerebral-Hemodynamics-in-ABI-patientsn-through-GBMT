DROP TABLE IF EXISTS dmin_icp;
CREATE TABLE dmin_icp AS
WITH vw0 AS (
	SELECT pt.stay_id,
		CAST(
			ROUND(
				EXTRACT(
					EPOCH
					FROM (tt.charttime - pt.intime)
				) / 60
			) AS INTEGER
		) AS chartoffset,
		-- TODO: handle high ICPs when monitoring two ICPs
		CASE
			WHEN tt.valuenum > 0
			AND tt.valuenum < 100 THEN tt.valuenum
			ELSE NULL
		END AS icp
	FROM icu.icustays pt
		INNER JOIN icu.chartevents tt ON pt.stay_id = tt.stay_id -- exclude rows marked as error
	WHERE itemid IN (
			220765,
			227989
			-- Intra Cranial Pressure -- 92306
			-- Intra Cranial Pressure #2 -- 1052
		)
)
SELECT DISTINCT stay_id,
	chartoffset,
	CAST(MAX(icp) AS NUMERIC) AS icp
FROM vw0
GROUP BY stay_id,
	chartoffset
ORDER BY stay_id,
	chartoffset;