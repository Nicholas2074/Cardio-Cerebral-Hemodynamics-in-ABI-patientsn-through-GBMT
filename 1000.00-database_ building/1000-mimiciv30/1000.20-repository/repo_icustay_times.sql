DROP TABLE IF EXISTS repo_icustay_times;
CREATE TABLE repo_icustay_times AS
-- create a table which has fuzzy boundaries on hospital admission
-- involves first creating a lag/lead version of disch/admit time
-- get first/last heart rate measurement during hospitalization for each stay_id
WITH tt AS (
	SELECT stay_id,
		MIN(charttime) AS intime_hr,
		MAX(charttime) AS outtime_hr
	FROM icu.chartevents -- only look at heart rate
	WHERE itemid = 220045
	GROUP BY stay_id
) -- add in subject_id/hadm_id
SELECT pt.subject_id,
	pt.hadm_id,
	pt.stay_id,
	tt.intime_hr,
	tt.outtime_hr
FROM icu.icustays pt
	LEFT JOIN tt ON pt.stay_id = tt.stay_id;