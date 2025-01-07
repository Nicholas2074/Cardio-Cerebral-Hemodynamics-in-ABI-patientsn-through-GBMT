-- //STUB - sahid_0
DROP MATERIALIZED VIEW IF EXISTS ichid_0;
CREATE MATERIALIZED VIEW ichid_0 AS 
WITH vw1 AS (
    SELECT DISTINCT hadm_id
    FROM hosp.diagnoses_icd
    WHERE icd_code ~ '^(I61|431)'
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