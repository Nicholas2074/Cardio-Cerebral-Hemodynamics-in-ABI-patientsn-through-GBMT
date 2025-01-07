-- //STUB - tbi_icd

/* -------------------------------------------------------------------------- */
-- SELECT icd_code, icd_version, long_title
-- 	FROM hosp.d_icd_diagnoses
-- WHERE
-- 	icd_code ILIKE '%XXX%';
/* -------------------------------------------------------------------------- */

-- 10版icd_code中代表头部损伤的编码:S00, S01, S02 S06,TO4
-- SOO: Superficial injury of head
-- SO1: Open wound of head
-- S02: Fracture of skull and facial bones
-- S06: Intracranial injury

-- 9版icd_code中代表头部损伤的编码:800, 801, 802, 803, 804, 850, 851, 852, 853, 854, 959
-- 800: Closed fracture of vault of skull without mention of intracranial injury, unspecified state of consciousness
-- 801: Closed fracture of base of skull without mention of intra cranial injury, unspecified state of consciousness
-- 802: Closed fracture of nasal bones
-- icd_code 9 802%为鼻骨闭合性骨折，是否计入TBI?
-- 803: Other closed skull fracture without mention of intracranial injury, unspecified state of consciousness
-- 804: Closed fractures involving skull or face with other bones, without mention of intracranial injury, unspecified state of consciousness
-- 850: Concussion with no loss of consciousness
-- 851: Cortex (cerebral) contusion without mention of open intracranial wound, unspecified state of consciousness
-- 852:: Subarachnoid hemorrhage following injury without mention of open intracranial wound, unspecified state of consciousness
-- 853: Other and unspecified intracranial hemorrhage following injury without mention of open intracranial wound, unspecified state of consciousness
-- 854: Intracranial injury of other and unspecified nature without mention of open intracranial wound, unspecified state of consciousness
-- 95901: Head injury, unspecified
-- 其余959% icd_code与TBI无关

-- 最后确定的icd_code
-- icd_code 10: S00%, S01%, S02%, S06%
-- icd_code 9: 800%, 801%, 803%, 804%, 850%, 851%, 852%, 853%, 854%, 95901%

-- 查询创伤性蛛血或创伤性硬膜外或硬膜下血肿的icd_code是否有遗漏
-- 没有遗漏
-- SELECT *
-- FROM hosp.d_icd_diagnoses
-- WHERE
-- (long_title ILIKE '%traumatic%haematoma%' AND NOT long_title ILIKE '%non%traumatic%')
-- OR
-- (long_title ILIKE '%traumatic%hematoma%' AND NOT long_title ILIKE '%non%traumatic%')
-- OR
-- (long_title ILIKE '%traumatic%hemorrhage%' AND NOT long_title ILIKE '%non%traumatic%')
-- ;

-- //STUB - tbiid_0
DROP MATERIALIZED VIEW IF EXISTS tbiid_0;
CREATE MATERIALIZED VIEW tbiid_0 AS 
WITH vw1 AS (
	SELECT DISTINCT hadm_id
	FROM hosp.diagnoses_icd
	WHERE SUBSTR(icd_code, 1, 3) IN (
			'S00',
			'S01',
			'S02',
			'S06',
			'800',
			'801',
			'803',
			'804',
			'850',
			'851',
			'852',
			'853',
			'854'
		)
		OR icd_code = '95901'
),
/* ---------------------------- 1st icu admission --------------------------- */
vw2 AS (
	SELECT DISTINCT subject_id,
		hadm_id,
		stay_id,
		ROW_NUMBER() OVER (
			PARTITION BY hadm_id
			ORDER BY intime ASC
		) AS pid,
		intime
	FROM icu.icustays
),
/* -------------------------------- age < 18 -------------------------------- */
vw3 AS (
	SELECT tt.subject_id,
		tt.hadm_id,
		pt.anchor_age + DATETIME_DIFF(
			tt.admittime,
			DATETIME(pt.anchor_year, 1, 1, 0, 0, 0),
			'YEAR'
		) AS age
	FROM hosp.admissions tt
		INNER JOIN hosp.patients pt ON tt.subject_id = pt.subject_id
),
/* ----------------------------- icu stay < 24h ----------------------------- */
vw4 AS (
	SELECT DISTINCT hadm_id,
		stay_id,
		los
	FROM icu.icustays
)
SELECT vw2.subject_id,
	vw2.hadm_id,
	vw2.stay_id,
	vw2.intime
FROM vw2
	INNER JOIN vw1 ON vw2.hadm_id = vw1.hadm_id
	INNER JOIN vw3 ON vw2.hadm_id = vw3.hadm_id
	INNER JOIN vw4 ON vw2.hadm_id = vw4.hadm_id
	AND vw4.stay_id = vw2.stay_id
WHERE vw2.pid = 1
	AND vw3.age >= 18
	AND vw4.los >= 1;