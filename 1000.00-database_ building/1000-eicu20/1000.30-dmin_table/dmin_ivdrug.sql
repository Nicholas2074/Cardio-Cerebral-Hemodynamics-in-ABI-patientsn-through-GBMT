-- //ANCHOR - mannitol
DROP TABLE IF EXISTS dmin_mannitol;
CREATE TABLE dmin_mannitol AS
SELECT DISTINCT tt.patientunitstayid,
    tt.infusionoffset,
    tt.drugname,
    tt.drugrate,
    tt.infusionrate
FROM icu.patient pt
    INNER JOIN icu.infusiondrug tt ON pt.patientunitstayid = tt.patientunitstayid
WHERE drugname ILIKE '%mannitol%';
-- //ANCHOR - hypertonic saline
DROP TABLE IF EXISTS dmin_hsaline;
CREATE TABLE dmin_hsaline AS
SELECT DISTINCT tt.patientunitstayid,
    tt.infusionoffset,
    tt.drugname,
    tt.drugrate,
    tt.infusionrate
FROM icu.patient pt
    INNER JOIN icu.infusiondrug tt ON pt.patientunitstayid = tt.patientunitstayid
WHERE drugname ILIKE '%hypertonic%saline%';