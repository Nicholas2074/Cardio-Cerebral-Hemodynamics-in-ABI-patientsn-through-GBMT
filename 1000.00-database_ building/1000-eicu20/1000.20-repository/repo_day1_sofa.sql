/* -------------------------------------------------------------------------- */
-- Based on sepsis-3
-- this code only caculate the fisrt day sofa score of icu admission
/* -------------------------------------------------------------------------- */
DROP TABLE IF EXISTS repo_day1_sofa;
CREATE TABLE repo_day1_sofa AS
-- //SECTION - sofa_cv
WITH sofa_cv AS (
	-- //ANCHOR - map
	WITH map AS (
		WITH tt1 AS (
			SELECT patientunitstayid,
				MIN(
					CASE
						WHEN noninvasivemean IS NOT NULL THEN noninvasivemean
						ELSE NULL
					END
				) AS map
			FROM icu.vitalaperiodic
			WHERE observationoffset BETWEEN -1440 AND 1440
			GROUP BY patientunitstayid
		),
		tt2 AS (
			SELECT patientunitstayid,
				MIN(
					CASE
						WHEN systemicmean IS NOT NULL THEN systemicmean
						ELSE NULL
					END
				) AS map
			FROM icu.vitalperiodic
			WHERE observationoffset BETWEEN -1440 AND 1440
			GROUP BY patientunitstayid
		)
		SELECT DISTINCT pt.patientunitstayid,
			CASE
				WHEN tt1.map IS NOT NULL THEN tt1.map
				WHEN tt2.map IS NOT NULL THEN tt2.map
				ELSE NULL
			END AS map
		FROM icu.patient pt
			LEFT JOIN tt1 ON tt1.patientunitstayid = pt.patientunitstayid
			LEFT JOIN tt2 ON tt2.patientunitstayid = pt.patientunitstayid
		ORDER BY pt.patientunitstayid
	), 
	-- //ANCHOR - dopamine
	dopamine AS (
		SELECT DISTINCT patientunitstayid,
			MAX(
				CASE
					WHEN LOWER(drugname) LIKE '%(ml/hr)%' THEN ROUND(CAST(drugrate AS NUMERIC) / 3, 3) -- rate in ml/h * 1600 mcg/ml / 80 kg / 60 min, to convert in mcg/kg/min
					WHEN LOWER(drugname) LIKE '%(mcg/kg/min)%' THEN CAST(drugrate AS NUMERIC)
					ELSE NULL
				END
			) AS dopa
		FROM icu.infusiondrug
		WHERE LOWER(drugname) LIKE '%dopamine%'
			AND infusionoffset BETWEEN -1440 AND 1440
			AND drugrate ~ '^[0-9]{0,5}$'
			AND drugrate <> ''
			AND drugrate <> '.'
		GROUP BY patientunitstayid
		ORDER BY patientunitstayid
	), 
	-- //ANCHOR - dobutamine
	dobutamine AS (
		SELECT DISTINCT patientunitstayid,
			1 AS dobu
		FROM icu.infusiondrug
		WHERE LOWER(drugname) LIKE '%dobutamin%'
			AND drugrate <> ''
			AND drugrate <> '.'
			AND drugrate <> '0'
			AND drugrate ~ '^[0-9]{0,5}$'
			AND infusionoffset BETWEEN -1440 AND 1440
		ORDER BY patientunitstayid
	),
	-- //ANCHOR - epinephrine
	epinephrine AS (
		SELECT DISTINCT patientunitstayid,
			MAX(
				CASE
					WHEN LOWER(drugname) LIKE '%(ml/hr)%'
					AND drugrate <> ''
					AND drugrate <> '.' THEN ROUND(CAST(drugrate AS NUMERIC) / 300, 3) -- rate in ml/h * 16 mcg/ml / 80 kg / 60 min, to convert in mcg/kg/min
					WHEN LOWER(drugname) LIKE '%(mcg/min)%'
					AND drugrate <> ''
					AND drugrate <> '.' THEN ROUND(CAST(drugrate AS NUMERIC) / 80, 3) -- divide by 80 kg
					WHEN LOWER(drugname) LIKE '%(mcg/kg/min)%'
					AND drugrate <> ''
					AND drugrate <> '.' THEN CAST(drugrate AS NUMERIC)
					ELSE NULL
				END
			) AS epine
		FROM icu.infusiondrug
		WHERE LOWER(drugname) LIKE '%epinephrine%'
			AND infusionoffset BETWEEN -1440 AND 1440
			AND drugrate ~ '^[0-9]{0,5}$'
			AND drugrate <> ''
			AND drugrate <> '.'
		GROUP BY patientunitstayid
		ORDER BY patientunitstayid
	),
	-- //ANCHOR - norepinephrine
	norepinephrine AS (
		SELECT DISTINCT patientunitstayid,
			MAX(
				CASE
					WHEN LOWER(drugname) LIKE '%(ml/hr)%'
					AND drugrate <> ''
					AND drugrate <> '.' THEN ROUND(CAST(drugrate AS NUMERIC) / 300, 3) -- rate in ml/h * 16 mcg/ml / 80 kg / 60 min, to convert in mcg/kg/min
					WHEN LOWER(drugname) LIKE '%(mcg/min)%'
					AND drugrate <> ''
					AND drugrate <> '.' THEN ROUND(CAST(drugrate AS NUMERIC) / 80, 3) -- divide by 80 kg
					WHEN LOWER(drugname) LIKE '%(mcg/kg/min)%'
					AND drugrate <> ''
					AND drugrate <> '.' THEN CAST(drugrate AS NUMERIC)
					ELSE NULL
				END
			) AS norepi
		FROM icu.infusiondrug
		WHERE LOWER(drugname) LIKE '%norepinephrine%'
			AND infusionoffset BETWEEN -1440 AND 1440
			AND drugrate ~ '^[0-9]{0,5}$'
			AND drugrate <> ''
			AND drugrate <> '.'
		GROUP BY patientunitstayid
		ORDER BY patientunitstayid
	) 
	-- //ANCHOR - sofacv
	-- coefficient allocation
	-- 0 = MAP ≥ 70mmHg
	-- 1 = MAP < 70mmHg
	-- 2 = dopamine (< 5ug/kg/min) ≥ 1h or any dose of dobutamine
	-- 3 = dopamine (5.1 - 15ug/kg/min) ≥ 1h or epinephrine (≤ 0.1ug/kg/min) ≥ 1h or norepinephrine (≤ 0.1ug/kg/min) ≥ 1h
	-- 4 = dopamine (> 15ug/kg/min) ≥ 1h or epinephrine (> 0.1ug/kg/min) ≥ 1h or norepinephrine (> 0.1ug/kg/min) ≥ 1h
	SELECT pt.patientunitstayid,
		map.map,
		dopamine.dopa,
		dobutamine.dobu,
		epinephrine.epine,
		norepinephrine.norepi,
		(
			CASE
				WHEN dopamine.dopa > 15
				OR epinephrine.epine > 0.1
				OR norepinephrine.norepi > 0.1 THEN 4
				WHEN (
					dopamine.dopa > 5
					AND dopamine.dopa <= 15
				)
				OR (
					norepinephrine.norepi > 0
					AND norepinephrine.norepi <= 0.1
				) THEN 3
				WHEN dopamine.dopa <= 5
				OR dobutamine.dobu > 0 THEN 2
				WHEN map.map < 70 THEN 1
				ELSE 0
			END
		) AS sofa_cv
	FROM icu.patient pt
		LEFT JOIN map ON map.patientunitstayid = pt.patientunitstayid
		LEFT JOIN dopamine ON dopamine.patientunitstayid = pt.patientunitstayid
		LEFT JOIN dobutamine ON dobutamine.patientunitstayid = pt.patientunitstayid
		LEFT JOIN epinephrine ON epinephrine.patientunitstayid = pt.patientunitstayid
		LEFT JOIN norepinephrine ON norepinephrine.patientunitstayid = pt.patientunitstayid
	ORDER BY pt.patientunitstayid
),
-- //!SECTION
-- //SECTION - sofa_respi
sofa_respi AS (
	-- //ANCHOR - sofa_respi
	WITH tempo2 AS (
		WITH tempo1 AS (
			/* -------------------------- t1 fio2_respcharting -------------------------- */
			WITH t1 AS (
				SELECT DISTINCT patientunitstayid,
					MAX(
						CASE
							WHEN LOWER(respchartvaluelabel) LIKE '%fio2%' THEN CAST(REPLACE(respchartvalue, '%', '') AS NUMERIC)
						END
					) AS rcfio2
				FROM icu.respiratorycharting
				WHERE respchartoffset BETWEEN -1440 AND 1440
				GROUP BY patientunitstayid
			)
			/* -------------------------- t2 fio2_nursecharting ------------------------- */
,
			t2 AS (
				SELECT DISTINCT patientunitstayid,
					MAX(
						CASE
							WHEN fio2 IS NOT NULL THEN fio2
							ELSE NULL
						END
					) AS ncfio2
				FROM public.repo_o2
				WHERE chartoffset BETWEEN -1440 AND 1440
				GROUP BY patientunitstayid
			)
			/* -------------------------- t3 sao2_vitalperiodic ------------------------- */
,
			t3 AS (
				SELECT patientunitstayid,
					MIN(
						CASE
							WHEN sao2 IS NOT NULL THEN sao2
							ELSE NULL
						END
					) AS sao2
				FROM icu.vitalperiodic
				WHERE observationoffset BETWEEN -1440 AND 1440
				GROUP BY patientunitstayid
			)
			/* ------------------------------- t4 pao2_lab ------------------------------ */
,
			t4 AS --pao2 from lab
			(
				SELECT patientunitstayid,
					MIN(
						CASE
							WHEN LOWER(labname) LIKE 'pao2%' THEN labresult
							ELSE NULL
						END
					) AS pao2
				FROM icu.lab
				WHERE labresultoffset BETWEEN -1440 AND 1440
				GROUP BY patientunitstayid
			)
			/* ---------------------------- t5 mechvent_multi --------------------------- */
,
			t5 AS -- ventilation support
			(
				WITH
				/* ------------------------------ tt1_respcare ------------------------------ */
				tt1 AS --airway type from respcare (1=invasive) 
				(
					SELECT DISTINCT patientunitstayid,
						MAX(
							CASE
								WHEN airwaytype in ('Oral ETT', 'Nasal ETT', 'Tracheostomy') THEN 1
								ELSE NULL
							END
						) AS airway -- either invasive airway or NULL
					FROM icu.respiratorycare
					WHERE respcarestatusoffset BETWEEN -1440 AND 1440
					GROUP BY patientunitstayid -- , respcarestatusoffset
				)
				/* ---------------------------- tt2_respcharting ---------------------------- */
,
				tt2 AS --airway type from respcharting (1=invasive)
				(
					SELECT DISTINCT patientunitstayid,
						1 AS ventilator
					FROM icu.respiratorycharting
					WHERE respchartvalue LIKE '%ventilator%'
						OR respchartvalue LIKE '%vent%'
						OR respchartvalue LIKE '%bipap%'
						OR respchartvalue LIKE '%840%'
						OR respchartvalue LIKE '%cpap%'
						OR respchartvalue LIKE '%drager%'
						OR respchartvalue LIKE 'mv%'
						OR respchartvalue LIKE '%servo%'
						OR respchartvalue LIKE '%peep%'
						AND respchartoffset BETWEEN -1440 AND 1440
					GROUP BY patientunitstayid
				)
				/* ------------------------------ tt3_treatment ----------------------------- */
,
				tt3 AS --airway type from treatment (1=invasive)
				(
					SELECT DISTINCT patientunitstayid,
						MAX(
							CASE
								WHEN treatmentstring in (
									'pulmonary|ventilation and oxygenation|mechanical ventilation',
									'pulmonary|ventilation and oxygenation|tracheal suctioning',
									'pulmonary|ventilation and oxygenation|ventilator weaning',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|assist controlled',
									'pulmonary|radiologic procedures / bronchoscopy|endotracheal tube',
									'pulmonary|ventilation and oxygenation|oxygen therapy (> 60%)',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|tidal volume 6-10 ml/kg',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|volume controlled',
									'surgery|pulmonary therapies|mechanical ventilation',
									'pulmonary|surgery / incision and drainage of thorax|tracheostomy',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|synchronized intermittent',
									'pulmonary|surgery / incision and drainage of thorax|tracheostomy|performed during current admission for ventilatory support',
									'pulmonary|ventilation and oxygenation|ventilator weaning|active',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|pressure controlled',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|pressure support',
									'pulmonary|ventilation and oxygenation|ventilator weaning|slow',
									'surgery|pulmonary therapies|ventilator weaning',
									'surgery|pulmonary therapies|tracheal suctioning',
									'pulmonary|radiologic procedures / bronchoscopy|reintubation',
									'pulmonary|ventilation and oxygenation|lung recruitment maneuver',
									'pulmonary|surgery / incision and drainage of thorax|tracheostomy|planned',
									'surgery|pulmonary therapies|ventilator weaning|rapid',
									'pulmonary|ventilation and oxygenation|prone position',
									'pulmonary|surgery / incision and drainage of thorax|tracheostomy|conventional',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|permissive hypercapnea',
									'surgery|pulmonary therapies|mechanical ventilation|synchronized intermittent',
									'pulmonary|medications|neuromuscular blocking agent',
									'surgery|pulmonary therapies|mechanical ventilation|assist controlled',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|volume assured',
									'surgery|pulmonary therapies|mechanical ventilation|tidal volume 6-10 ml/kg',
									'surgery|pulmonary therapies|mechanical ventilation|pressure support',
									'pulmonary|ventilation and oxygenation|non-invasive ventilation',
									'pulmonary|ventilation and oxygenation|non-invasive ventilation|face mask',
									'pulmonary|ventilation and oxygenation|non-invasive ventilation|nasal mask',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation|face mask',
									'surgery|pulmonary therapies|non-invasive ventilation',
									'surgery|pulmonary therapies|non-invasive ventilation|face mask',
									'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation|nasal mask',
									'surgery|pulmonary therapies|non-invasive ventilation|nasal mask',
									'surgery|pulmonary therapies|mechanical ventilation|non-invasive ventilation',
									'surgery|pulmonary therapies|mechanical ventilation|non-invasive ventilation|face mask'
								) THEN 1
								ELSE NULL
							END
						) AS interface -- either ETT/NiV or NULL
					FROM icu.treatment
					WHERE treatmentoffset BETWEEN -1440 AND 1440
					GROUP BY patientunitstayid -- , treatmentoffset, interface
					ORDER BY patientunitstayid -- , treatmentoffset
				)
				/* --------------------------- tt4_careplangeneral -------------------------- */
,
				tt4 AS (
					SELECT DISTINCT patientunitstayid,
						MAX(
							CASE
								WHEN cplitemvalue ILIKE '%intubated%'
								AND cplitemvalue NOT ILIKE '%not intubated' THEN 1
								ELSE NULL
							END
						) AS intubated -- either invasive airway or NULL
					FROM icu.careplangeneral
					WHERE cplitemoffset BETWEEN -1440 AND 1440
					GROUP BY patientunitstayid,
						cplitemoffset
				)
				SELECT pt.patientunitstayid,
					CASE
						WHEN tt1.airway IS NOT NULL
						OR tt2.ventilator IS NOT NULL
						OR tt3.interface IS NOT NULL
						OR tt4.intubated IS NOT NULL THEN 1
						ELSE NULL
					END AS mechvent
				FROM icu.patient pt
					LEFT JOIN tt1 ON tt1.patientunitstayid = pt.patientunitstayid
					LEFT JOIN tt2 ON tt2.patientunitstayid = pt.patientunitstayid
					LEFT JOIN tt3 ON tt3.patientunitstayid = pt.patientunitstayid
					LEFT JOIN tt4 ON tt4.patientunitstayid = pt.patientunitstayid
			)
			SELECT pt.patientunitstayid,
				(
					CASE
						WHEN t1.rcfio2 > 20 THEN t1.rcfio2
						WHEN t2.ncfio2 > 20 THEN t2.ncfio2
						WHEN t1.rcfio2 = 1
						OR t2.ncfio2 = 1 THEN 100
						ELSE NULL
					END
				) AS fio2,
				(
					CASE
						WHEN t3.sao2 > 0 THEN t3.sao2
						WHEN t4.pao2 > 0 THEN t4.pao2
						ELSE NULL
					END
				) AS spo2,
				t5.mechvent
			FROM icu.patient pt
				LEFT JOIN t1 ON t1.patientunitstayid = pt.patientunitstayid
				LEFT JOIN t2 ON t2.patientunitstayid = pt.patientunitstayid
				LEFT JOIN t3 ON t3.patientunitstayid = pt.patientunitstayid
				LEFT JOIN t4 ON t4.patientunitstayid = pt.patientunitstayid
				LEFT JOIN t5 ON t5.patientunitstayid = pt.patientunitstayid
		)
		SELECT *,
			(
				100 * COALESCE(spo2, 100) / COALESCE(NULLIF(fio2, 0), 21)
			) AS pf
		FROM tempo1
	) -- coefficient allocation
	-- 0 = pao2/fio2 > 400mmHg
	-- 1 = pao2/fio2 <= 400mmHg
	-- 2 = pao2/fio2 <= 300mmHg
	-- 3 = pao2/fio2 <= 200mmHg with ventilation
	-- 4 = pao2/fio2 <= 100mmHg with ventilation
	SELECT patientunitstayid,
		(
			CASE
				WHEN pf <= 100
				AND mechvent IS NOT NULL THEN 4
				WHEN pf <= 200
				AND mechvent IS NOT NULL THEN 3
				WHEN pf <= 300 THEN 2
				WHEN PF <= 400 THEN 1
				ELSE 0
			END
		) AS sofa_respi
	FROM tempo2
	ORDER BY patientunitstayid
),
-- //!SECTION
-- //SECTION - sofa_renal
sofa_renal AS (
	-- //ANCHOR - t1 creatinine
	WITH t1 AS (
		SELECT pt.patientunitstayid,
			MAX(
				CASE
					WHEN LOWER(labname) LIKE 'creatin%' THEN labresult
					ELSE NULL
				END
			) AS creat
		FROM icu.patient pt
			LEFT JOIN icu.lab ON pt.patientunitstayid = lab.patientunitstayid
		WHERE labresultoffset BETWEEN -1440 AND 1440
		GROUP BY pt.patientunitstayid
	),
	-- //ANCHOR - t2 uo
	t2 AS (
		WITH uotemp AS (
			SELECT patientunitstayid,
				CASE
					WHEN dayz = 1 THEN SUM(outputtotal)
					ELSE NULL
				END AS uod1
			FROM (
					SELECT DISTINCT patientunitstayid,
						intakeoutputoffset,
						outputtotal,
						(
							CASE
								WHEN (intakeoutputoffset) BETWEEN -1440 AND 1440 THEN 1
								ELSE NULL
							END
						) AS dayz
					FROM icu.intakeoutput
					ORDER BY patientunitstayid,
						intakeoutputoffset
				) AS temp
			GROUP BY patientunitstayid,
				temp.dayz
		)
		SELECT pt.patientunitstayid,
			MAX(
				CASE
					WHEN uod1 IS NOT NULL THEN uod1
					ELSE NULL
				END
			) AS uo
		FROM icu.patient pt
			LEFT JOIN uotemp ON uotemp.patientunitstayid = pt.patientunitstayid
		GROUP BY pt.patientunitstayid
	) -- 0 = cr < 1.2 mg/dl
	-- 1 = cr < 2 mg/dl
	-- 2 = cr < 3.5 mg/dl
	-- 3 = cr < 5 mg/dl or uo < 500 ml/day
	-- 4 = cr > 5 mg/dl or uo < 200 ml/day
	SELECT pt.patientunitstayid,
		-- , t1.creat
		-- , t2.uo
		(
			CASE
				WHEN uo < 200
				OR creat > 5 THEN 4
				WHEN uo < 500
				OR creat > 3.5 THEN 3
				WHEN creat BETWEEN 2 AND 3.5 THEN 2
				WHEN creat BETWEEN 1.2 AND 2 THEN 1
				ELSE 0
			END
		) AS sofa_renal
	FROM icu.patient pt
		LEFT JOIN t1 ON t1.patientunitstayid = pt.patientunitstayid
		LEFT JOIN t2 ON t2.patientunitstayid = pt.patientunitstayid
	ORDER BY pt.patientunitstayid
),
-- //!SECTION
-- //SECTION - sofa_3others
sofa_3others AS (
	-- //ANCHOR - t1 sofa_cns
	WITH t1 AS (
		SELECT patientunitstayid,
			SUM(CAST(physicalexamvalue AS NUMERIC)) AS gcs
		FROM icu.physicalexam pe
		WHERE (
				LOWER(physicalexampath) LIKE '%gcs/eyes%'
				OR LOWER(physicalexampath) LIKE '%gcs/verbal%'
				OR LOWER(physicalexampath) LIKE '%gcs/motor%'
			)
			AND physicalexamoffset BETWEEN -1440 AND 1440
		GROUP BY patientunitstayid
	),
	-- //ANCHOR - t2 sofa_liver, sofa_coag
	t2 AS (
		SELECT pt.patientunitstayid,
			MAX(
				CASE
					WHEN LOWER(labname) LIKE 'total bili%' THEN labresult
					ELSE NULL
				END
			) AS bili, -- sofa_liver
			MIN(
				CASE
					WHEN LOWER(labname) LIKE 'platelet%' THEN labresult
					ELSE NULL
				END
			) AS plt -- sofa_coag
		FROM icu.patient pt
			LEFT JOIN icu.lab ON pt.patientunitstayid = lab.patientunitstayid
		WHERE labresultoffset BETWEEN -1440 AND 1440
		GROUP BY pt.patientunitstayid
	)
	SELECT DISTINCT pt.patientunitstayid,
		MAX(
			CASE
				WHEN plt < 20 THEN 4
				WHEN plt < 50 THEN 3
				WHEN plt < 100 THEN 2
				WHEN plt < 150 THEN 1
				ELSE 0
			END
		) AS sofa_coag,
		MAX(
			CASE
				WHEN bili < 1.2 THEN 0
				WHEN bili < 2 THEN 1
				WHEN bili < 6 THEN 2
				WHEN bili < 12 THEN 3
				ELSE 4
			END
		) AS sofa_liver,
		MAX(
			CASE
				WHEN gcs > 14 THEN 0
				WHEN gcs > 12 THEN 1
				WHEN gcs > 9 THEN 2
				WHEN gcs > 5 THEN 3
				ELSE 4
			END
		) AS sofa_cns
	FROM icu.patient pt
		LEFT JOIN t1 ON t1.patientunitstayid = pt.patientunitstayid
		LEFT JOIN t2 ON t2.patientunitstayid = pt.patientunitstayid
	GROUP BY pt.patientunitstayid
	ORDER BY pt.patientunitstayid
) -- //!SECTION
-- //SECTION - total
SELECT pt.patientunitstayid,
	(
		t1.sofa_cv + t2.sofa_respi + t3.sofa_renal + t4.sofa_coag + t4.sofa_liver + t4.sofa_cns
	) AS sofa
FROM icu.patient pt
	LEFT JOIN sofa_cv t1 ON pt.patientunitstayid = t1.patientunitstayid
	LEFT JOIN sofa_respi t2 ON pt.patientunitstayid = t2.patientunitstayid
	LEFT JOIN sofa_renal t3 ON pt.patientunitstayid = t3.patientunitstayid
	LEFT JOIN sofa_3others t4 ON pt.patientunitstayid = t4.patientunitstayid;
-- -- //!SECTION