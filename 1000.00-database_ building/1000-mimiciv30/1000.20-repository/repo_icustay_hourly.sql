DROP TABLE IF EXISTS repo_icustay_hourly;
CREATE TABLE repo_icustay_hourly AS
-- This query generates a row for every hour the patient is in the ICU.
-- The hours are based on clock-hours (i.e. 02:00, 03:00).
-- The hour clock starts 24 hours before the first heart rate measurement.
-- Note that the time of the first heart rate measurement is ceilinged to
-- the hour.
-- this query extracts the cohort and every possible hour they were in the ICU
-- this table can be to other tables on stay_id and (ENDTIME - 1 hour,ENDTIME]
-- get first/last measurement time
WITH all_hours AS (
	SELECT stay_id,
		-- ceiling the intime to the nearest hour by adding 59 minutes,
		-- then applying truncate by parsing as string
		-- string truncate is done to enable compatibility with psql
		PARSE_DATETIME(
			'%Y-%m-%d %H:00:00',
			FORMAT_DATETIME(
				'%Y-%m-%d %H:00:00',
				DATETIME_ADD(intime_hr, INTERVAL '59' MINUTE)
			)
		) AS endtime,
		-- create integers for each charttime in hours from admission
		-- so 0 is admission time, 1 is one hour after admission, etc,
		-- up to ICU disch
		--  we allow 24 hours before ICU admission (to grab labs before admit)
		ARRAY(
			SELECT *
			FROM generate_series(
					-24,
					CEIL(
						DATETIME_DIFF(outtime_hr, intime_hr, 'HOUR')
					)
				)
		) AS hrs -- noqa: L016
	FROM public.icustay_times
)
SELECT stay_id,
	CAST(hr AS bigint) AS hr,
	DATETIME_ADD(endtime, interval '1' hour * CAST(hr AS bigint)) AS endtime
FROM all_hours
	CROSS JOIN UNNEST(all_hours.hrs) AS hr;