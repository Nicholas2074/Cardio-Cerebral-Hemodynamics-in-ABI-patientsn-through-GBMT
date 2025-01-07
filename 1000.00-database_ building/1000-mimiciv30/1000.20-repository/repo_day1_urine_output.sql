DROP TABLE IF EXISTS repo_day1_urine_output;
CREATE TABLE repo_day1_urine_output AS
/* Total urine output over the first 24 hours in the ICU */
SELECT ie.subject_id,
	ie.stay_id,
	SUM(urineoutput) AS urineoutput
FROM icu.icustays ie
	/* Join to the outputevents table to get urine output */
	LEFT JOIN public.repo_urine_output uo ON ie.stay_id = uo.stay_id
	AND uo.charttime >= ie.intime
	AND uo.charttime <= ie.intime + INTERVAL '1 DAY'
GROUP BY ie.subject_id,
	ie.stay_id