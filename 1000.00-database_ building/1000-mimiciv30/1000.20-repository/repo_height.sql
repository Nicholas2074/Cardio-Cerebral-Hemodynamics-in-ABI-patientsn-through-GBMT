DROP TABLE IF EXISTS repo_height;
CREATE TABLE repo_height AS
WITH ht AS (
WITH ht_in AS (
	SELECT stay_id,
		charttime,
		ROUND(CAST(valuenum * 2.54 AS NUMERIC), 2) AS height, -- Ensure that all heights are in centimeters
		valuenum AS height_orig -- for debug
	FROM icu.chartevents
	WHERE valuenum IS NOT NULL -- Height (measured in inches)
		AND itemid = 226707
),
ht_cm AS (
	SELECT stay_id,
		charttime,
		ROUND(CAST(valuenum AS NUMERIC), 2) AS height -- Ensure that all heights are in centimeters
	FROM icu.chartevents
	WHERE valuenum IS NOT NULL -- Height cm
		AND itemid = 226730
)
-- merge cm/height, only take 1 value per charted row
SELECT ht_in.stay_id,
	ht_in.charttime,
	ht_in.height
FROM ht_in
UNION
SELECT ht_cm.stay_id,
	ht_cm.charttime,
	ht_cm.height
FROM ht_cm
)
SELECT stay_id,
	charttime,
	MAX(height) AS height
FROM ht
WHERE height > 120
	AND height < 230
GROUP BY stay_id,
	charttime;