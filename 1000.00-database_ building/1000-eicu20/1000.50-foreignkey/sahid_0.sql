-- //STUB - tbiid_0
-- use the determined icd_code from the mimic to query tbi patients
DROP MATERIALIZED VIEW IF EXISTS sahid_0;
CREATE MATERIALIZED VIEW sahid_0 AS
WITH vw1 AS (
    SELECT DISTINCT patientunitstayid
    FROM icu.diagnosis
    WHERE icd9code ~ '^(430|8002|8007|8012|8017|8032|8037|8042|8047|8520|8521|I60|S066)'
),
/* ---------------------------- 1st icu admission --------------------------- */
vw2 AS (
    SELECT patientunitstayid,
        ROW_NUMBER() OVER (
            PARTITION BY patienthealthsystemstayid
            ORDER BY ABS(hospitaladmitoffset) ASC
        ) AS pid,
        patienthealthsystemstayid
    FROM icu.patient
),
/* -------------------------------- age < 18 -------------------------------- */
vw3 AS (
    SELECT DISTINCT patientunitstayid,
        CASE
            WHEN age ILIKE '%> 89%' THEN 90.0
            WHEN age = '' THEN NULL
            ELSE age::NUMERIC
        END AS age
    FROM icu.patient
),
/* ----------------------------- icu stay < 24h ----------------------------- */
vw4 AS (
    SELECT DISTINCT patientunitstayid,
        unitdischargeoffset
    FROM icu.patient
)
SELECT vw1.patientunitstayid
FROM vw1
    INNER JOIN vw2 ON vw1.patientunitstayid = vw2.patientunitstayid
    INNER JOIN vw3 ON vw1.patientunitstayid = vw3.patientunitstayid
    INNER JOIN vw4 ON vw1.patientunitstayid = vw4.patientunitstayid
WHERE vw2.pid = 1
    AND vw3.age >= 18
    AND vw4.unitdischargeoffset >= 1440;