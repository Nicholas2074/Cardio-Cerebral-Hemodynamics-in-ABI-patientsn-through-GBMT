-- //STUB - sah_icd

-- 分别查询9版与10版中的sah的icd_code

-- SELECT *
-- 	FROM mimic_hosp.d_icd_diagnoses
-- 	WHERE long_title ILIKE '%subarachnoid%hemorrhage%'
-- ;

/* -------------------------------------------------------------------------- */
-- SELECT icd_code, icd_version, long_title
-- 	FROM mimic_hosp.d_icd_diagnoses
-- WHERE
-- 	icd_code LIKE 'XXX'
-- ;
/* -------------------------------------------------------------------------- */

-- n=1
-- SELECT *
-- 	FROM mimic_hosp.d_icd_diagnoses
-- 	WHERE icd_code = '430'
-- ;

-- n=8
-- SELECT *
-- 	FROM mimic_hosp.d_icd_diagnoses
-- 	WHERE icd_code ILIKE '8002%'
-- ;

-- n=8
-- icd_code ILIKE '8007%'

-- n=8
-- icd_code ILIKE '8012%'

-- n=8
-- icd_code ILIKE '8017%'

-- n=8
-- icd_code ILIKE '8032%'

-- n=8
-- icd_code ILIKE '8037%'

-- n=8
-- icd_code ILIKE '8042%'

-- n=8
-- icd_code ILIKE '8047%'

-- n=8
-- icd_code ILIKE '8520%'

-- n=8
-- icd_code ILIKE '8521%'

-- n=26
-- icd_code ILIKE 'I60%'

-- n=42
-- icd_code ILIKE 'S066%'

-- icd_code本身不连续，非关键词查询结果的缺失

-- icd_code: 430, 8002%, 8007%, 8012%, 8017%, 8032%, 8037%, 8042%, 8047%, 8520%, 8521%, I60%, S066%

-- //STUB - sahid_0
DROP MATERIALIZED VIEW IF EXISTS sahid_0;
CREATE MATERIALIZED VIEW sahid_0 AS 
WITH vw1 AS (
    SELECT DISTINCT hadm_id
    FROM hosp.diagnoses_icd
    WHERE icd_code ~ '^(430|8002|8007|8012|8017|8032|8037|8042|8047|8520|8521|I60|S066)'
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