DROP TABLE IF EXISTS dmin_icd;
CREATE TABLE dmin_icd AS
SELECT tt.patientunitstayid,
	tt.diagnosisoffset,
	tt.diagnosispriority,
	tt.icd9code,
	tt.diagnosisstring,
	tt.activeupondischarge
FROM icu.patient pt
	INNER JOIN icu.diagnosis tt ON pt.patientunitstayid = tt.patientunitstayid;