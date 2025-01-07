DROP TABLE IF EXISTS repo_age;
CREATE TABLE repo_age AS 
-- the age of a patient = admission time - anchor_year + anchor_age
SELECT tt.subject_id,
	tt.hadm_id,
	tt.admittime,
	pt.anchor_age,
	pt.anchor_year, 
	-- calculate the age as anchor_age (60) plus difference between
	-- admit year and the anchor year.
	-- the noqa retains the extra long line so the 
	-- convert to postgres bash script works
	pt.anchor_age + DATETIME_DIFF(
		tt.admittime,
		DATETIME(pt.anchor_year, 1, 1, 0, 0, 0),
		'YEAR'
	) AS age -- noqa: L016
FROM hosp.admissions tt
	INNER JOIN hosp.patients pt ON tt.subject_id = pt.subject_id;
