DROP TABLE IF EXISTS repo_dopamine;
CREATE TABLE repo_dopamine AS
/* This query extracts dose+durations of dopamine administration */
/* Local hospital dosage guidance: 2 mcg/kg/min (low) - 10 mcg/kg/min (high) */
SELECT stay_id,
	linkorderid,
	/* all rows in mcg/kg/min */
	rate AS vaso_rate,
	amount AS vaso_amount,
	starttime,
	endtime
FROM icu.inputevents
WHERE itemid = 221662
	/* dopamine */