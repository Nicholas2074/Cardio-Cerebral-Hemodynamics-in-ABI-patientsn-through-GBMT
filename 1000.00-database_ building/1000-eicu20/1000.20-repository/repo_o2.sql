DROP TABLE IF EXISTS repo_o2;
CREATE TABLE repo_o2 AS WITH vw1 AS (
	SELECT patientunitstayid,
		nursingchartoffset,
		nursingchartentryoffset,
		CASE
			WHEN nursingchartcelltypevallabel = 'O2 L/%'
			AND nursingchartcelltypevalname = 'O2 L/%'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS o2_flow,
		CASE
			WHEN nursingchartcelltypevallabel = 'O2 Admin Device'
			AND nursingchartcelltypevalname = 'O2 Admin Device' THEN nursingchartvalue
			ELSE NULL
		END AS o2_device,
		CASE
			WHEN nursingchartcelltypevallabel = 'End Tidal CO2'
			AND nursingchartcelltypevalname = 'End Tidal CO2'
			AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
			AND nursingchartvalue NOT IN ('-', '.') THEN CAST(nursingchartvalue AS NUMERIC)
			ELSE NULL
		END AS etco2
	FROM icu.nursecharting
	WHERE nursingchartcelltypecat = 'Vital Signs'
)
SELECT patientunitstayid,
	nursingchartoffset AS chartoffset,
	nursingchartentryoffset AS entryoffset,
	ROUND(
		AVG(
			CASE
				WHEN o2_flow >= 0
				AND o2_flow <= 100 THEN o2_flow
				ELSE NULL
			END
		),
		2
	) AS o2_flow,
	o2_device,
	ROUND(
		AVG(
			CASE
				WHEN etco2 >= 0
				AND etco2 <= 1000 THEN etco2
				ELSE NULL
			END
		),
		2
	) AS etco2,
	ROUND(
		(
			21 + 4 * AVG(
				CASE
					WHEN o2_flow >= 0
					AND o2_flow <= 100 THEN o2_flow
					ELSE NULL
				END
			)
		),
		2
	) AS fio2
FROM vw1
WHERE o2_flow IS NOT NULL
	OR o2_device IS NOT NULL
	OR etco2 IS NOT NULL
GROUP BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset,
	o2_device
ORDER BY patientunitstayid,
	nursingchartoffset,
	nursingchartentryoffset,
	o2_device;