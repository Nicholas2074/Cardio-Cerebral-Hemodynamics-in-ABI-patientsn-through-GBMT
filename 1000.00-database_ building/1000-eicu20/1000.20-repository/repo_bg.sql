DROP TABLE IF EXISTS repo_bg;
CREATE TABLE repo_bg AS
with vw0 AS (
	SELECT patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	FROM icu.lab
	WHERE labname IN (
			'pH',
			'FiO2',
			'paO2',
			'paCO2',
			'anion gap',
			'HCO3',
			'Base Deficit',
			'Base Excess',
			'PEEP'
		)
	GROUP BY patientunitstayid,
		labname,
		labresultoffset,
		labresultrevisedoffset
	HAVING COUNT(DISTINCT labresult) <= 1
), -- get the last lab to be revised
vw1 AS (
	SELECT lab.patientunitstayid,
		lab.labname,
		lab.labresultoffset,
		lab.labresultrevisedoffset,
		lab.labresult,
		ROW_NUMBER() OVER (
			PARTITION BY lab.patientunitstayid,
			lab.labname,
			lab.labresultoffset
			ORDER BY lab.labresultrevisedoffset DESC
		) AS rn
	FROM icu.lab
		INNER JOIN vw0 ON lab.patientunitstayid = vw0.patientunitstayid
		AND lab.labname = vw0.labname
		AND lab.labresultoffset = vw0.labresultoffset
		AND lab.labresultrevisedoffset = vw0.labresultrevisedoffset
	WHERE
		(
			lab.labname = 'pH'
			AND lab.labresult >= 6.5
			AND lab.labresult <= 8.5
		)
		OR (
			lab.labname = 'FiO2'
			AND lab.labresult >= 0.2
			AND lab.labresult <= 1.0
		) -- we will fix fio2 units later
		OR (
			lab.labname = 'paO2'
			AND lab.labresult >= 15
			AND lab.labresult <= 720
		)
		OR (
			lab.labname = 'paCO2'
			AND lab.labresult >= 5
			AND lab.labresult <= 250
		)
		OR (
			lab.labname = 'anion gap'
			AND lab.labresult >= 0
			AND lab.labresult <= 300
		)
		OR (
			lab.labname = 'HCO3'
			AND lab.labresult >= 20
			AND lab.labresult <= 100
		)
		OR (
			lab.labname = 'Base Deficit'
			AND lab.labresult >= -100
			AND lab.labresult <= 100
		)
		OR (
			lab.labname = 'Base Excess'
			AND lab.labresult >= -100
			AND lab.labresult <= 100
		)
		OR (
			lab.labname = 'PEEP'
			AND lab.labresult >= 0
			AND lab.labresult <= 60
		)
)
SELECT patientunitstayid,
	labresultoffset AS chartoffset, -- the aggregate (max()) only ever applies to 1 value due to the where clause
	MAX(
		CASE
			WHEN labname = 'pH' THEN labresult
			ELSE NULL
		END
	) AS ph,
	MAX(
		CASE
			WHEN labname = 'FiO2'
				AND labresult >= 0
				AND labresult < 20 THEN labresult
			WHEN labname = 'FiO2'
				AND labresult >= 20 THEN labresult / 100.0
			ELSE NULL
		END
	) AS fio2,
	MAX(
		CASE
			WHEN labname = 'paO2' THEN labresult
			ELSE NULL
		END
	) AS pao2,
	MAX(
		CASE
			WHEN labname = 'paCO2' THEN labresult
			ELSE NULL
		END
	) AS paco2,
	MAX(
		CASE
			WHEN labname = 'anion gap' THEN labresult
			ELSE NULL
		END
	) AS aniongap,
	MAX(
		CASE
			WHEN labname = 'HCO3' THEN labresult
			ELSE NULL
		END
	) AS bicarbonate,
	MAX(
		CASE
			WHEN labname = 'Base Deficit' THEN labresult
			ELSE NULL
		END
	) AS basedeficit,
	MAX(
		CASE
			WHEN labname = 'Base Excess' THEN labresult
			ELSE NULL
		END
	) AS baseexcess,
	MAX(
		CASE
			WHEN labname = 'PEEP' THEN labresult
			ELSE NULL
		END
	) AS peep -- labtypeid = 7, bg analysis include the PEEP value for unknown reasons
FROM vw1
WHERE rn = 1
GROUP BY patientunitstayid,
	labresultoffset
ORDER BY patientunitstayid,
	labresultoffset;