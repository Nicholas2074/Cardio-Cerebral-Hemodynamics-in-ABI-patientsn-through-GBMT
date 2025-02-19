DROP TABLE IF EXISTS repo_charlson;
CREATE TABLE repo_charlson AS
WITH vw0 AS (
	SELECT pt.patientunitstayid,
		-- //ANCHOR - cerebrovascular disease
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/Strokes/multiple/multiple',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/Strokes/stroke - remote',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/Strokes/stroke - within 5 years',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/Strokes/stroke - within 2 years',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/Strokes/stroke - date unknown',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/Strokes/stroke - within 6 months'
				) THEN 2
				ELSE 0
			END
		) AS cerebrovascular_disease,
		-- //ANCHOR - hemiplegia or paraplegia
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/TIA(s)/TIA(s) - within 6 months',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/TIA(s)/TIA(s) - within 2 years',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/TIA(s)/TIA(s) - remote',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/TIA(s)/TIA(s) - within 5 years',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/TIA(s)/multiple/multiple',
					'notes/Progress Notes/Past History/Organ Systems/Neurologic/TIA(s)/TIA(s) - date unknown'
				) THEN 1
				ELSE 0
			END
		) AS paraplegia,
		-- //ANCHOR - dementia
		MAX (
			CASE
				WHEN tt.pasthistorypath = 'notes/Progress Notes/Past History/Organ Systems/Neurologic/Dementia/dementia' THEN 1
				ELSE 0
			END
		) AS dementia,
		-- //ANCHOR - myocardial infarction
		MAX (
			CASE
				WHEN tt.pasthistorypath IN(
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Myocardial Infarction/MI - within 5 years',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Myocardial Infarction/MI - remote',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Myocardial Infarction/MI - within 6 months',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Myocardial Infarction/MI - date unknown',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Myocardial Infarction/MI - within 2 years',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Myocardial Infarction/multiple/multiple'
				) THEN 1
				ELSE 0
			END
		) AS myocardial_infarct,
		-- //ANCHOR - congestive heart failure
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Congestive Heart Failure/CHF',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Congestive Heart Failure/CHF - class I',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Congestive Heart Failure/CHF - class II',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Congestive Heart Failure/CHF - class III',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Congestive Heart Failure/CHF - class IV',
					'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Congestive Heart Failure/CHF - severity unknown'
				) THEN 1
				ELSE 0
			END
		) AS congestive_heart_failure,
		-- //ANCHOR - peripheral vascular disease
		MAX (
			CASE
				WHEN tt.pasthistorypath = 'notes/Progress Notes/Past History/Organ Systems/Cardiovascular (R)/Peripheral Vascular Disease/peripheral vascular disease' THEN 1
				ELSE 0
			END
		) AS peripheral_vascular_disease,
		-- //ANCHOR - chronic pulmonary disease
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Pulmonary/COPD/COPD  - no limitations',
					'notes/Progress Notes/Past History/Organ Systems/Pulmonary/COPD/COPD  - moderate',
					'notes/Progress Notes/Past History/Organ Systems/Pulmonary/COPD/COPD  - severe'
				) THEN 1
				ELSE 0
			END
		) AS chronic_pulmonary_disease,
		-- //ANCHOR - rheumatic disease
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Rheumatic/SLE/SLE',
					'notes/Progress Notes/Past History/Organ Systems/Rheumatic/Rheumatoid Arthritis/rheumatoid arthritis',
					'notes/Progress Notes/Past History/Organ Systems/Rheumatic/Scleroderma/scleroderma',
					'notes/Progress Notes/Past History/Organ Systems/Rheumatic/Vasculitis/vasculitis',
					'notes/Progress Notes/Past History/Organ Systems/Rheumatic/Dermato/Polymyositis/dermatomyositis'
				) THEN 1
				ELSE 0
			END
		) AS rheumatic_disease,
		-- //ANCHOR - peptic ulcer disease
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Peptic Ulcer Disease/peptic ulcer disease',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Peptic Ulcer Disease/peptic ulcer disease with h/o GI bleeding',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Peptic Ulcer Disease/hx GI bleeding/no'
				) THEN 1
				ELSE 0
			END
		) AS peptic_ulcer_disease,
		-- //ANCHOR - liver disease
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/clinical diagnosis',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/biopsy proven'
				) THEN 1
				ELSE 0
			END
		) AS mild_liver_disease,
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/UGI bleeding',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/varices',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/coma',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/jaundice',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/ascites',
					'notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/encephalopathy'
				) THEN 3
				ELSE 0
			END
		) AS severe_liver_disease,
		-- //ANCHOR - renal disease
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Insufficiency/renal insufficiency - creatinine 1-2',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Insufficiency/renal insufficiency - creatinine 3-4',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Insufficiency/renal insufficiency - creatinine > 5',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Insufficiency/renal insufficiency - baseline creatinine unknown',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Insufficiency/renal insufficiency - creatinine 4-5',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Insufficiency/renal insufficiency - creatinine 2-3',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Failure/renal failure - peritoneal dialysis',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Failure/renal failure- not currently dialyzed',
					'notes/Progress Notes/Past History/Organ Systems/Renal  (R)/Renal Failure/renal failure - hemodialysis'
				) THEN 2
				ELSE 0
			END
		) AS renal_disease,
		-- //ANCHOR - diabetes
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Endocrine (R)/Insulin Dependent Diabetes/insulin dependent diabetes',
					'notes/Progress Notes/Past History/Organ Systems/Endocrine (R)/Non-Insulin Dependent Diabetes/non-medication dependent',
					'notes/Progress Notes/Past History/Organ Systems/Endocrine (R)/Non-Insulin Dependent Diabetes/medication dependent'
				) THEN 1
				ELSE 0
			END
		) AS diabetes,
		-- //ANCHOR - cancer
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Chemotherapy/Anthracyclines (adriamycin, daunorubicin)',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/bone',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/stomach',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/bile duct',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/kidney',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/unknown',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Radiation Therapy within past 6 months/primary site',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/breast',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/uterus',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Radiation Therapy within past 6 months/bone',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/prostate',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/liver',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/pancreas - adenocarcinoma',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/ovary',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Radiation Therapy within past 6 months/other',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/sarcoma',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Chemotherapy/chemotherapy within past mo.',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/other',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Chemotherapy/Alkylating agents (bleomycin, cytoxan, cyclophos.)',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/testes',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/lung',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/melanoma',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Radiation Therapy within past 6 months/nodes',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Chemotherapy/BMT within past 12 mos.',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Chemotherapy/Cis-platinum',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Radiation Therapy within past 6 months/liver',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/head and neck',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/esophagus',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/bladder',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Chemotherapy/chemotherapy within past 6 mos.',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Radiation Therapy within past 6 months/lung',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/none',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/pancreas - islet cell',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/colon',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Radiation Therapy within past 6 months/brain',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer Therapy/Chemotherapy/Vincristine',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Cancer-Primary Site/brain'
				) THEN 2
				ELSE 0
			END
		) AS cancer,
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Hematologic Malignancy/AML',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Hematologic Malignancy/ALL',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Hematologic Malignancy/CLL',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Hematologic Malignancy/CML',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Hematologic Malignancy/leukemia - other'
				) THEN 2
				ELSE 0
			END
		) AS leukemia,
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Hematologic Malignancy/non-Hodgkins lymphoma',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Hematologic Malignancy/Hodgkins disease'
				) THEN 2
				ELSE 0
			END
		) AS lymphoma,
		MAX (
			CASE
				WHEN tt.pasthistorypath IN (
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/other',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/brain',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/carcinomatosis',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/nodes',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/lung',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/intra-abdominal',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/bone',
					'notes/Progress Notes/Past History/Organ Systems/Hematology/Oncology (R)/Cancer/Metastases/liver'
				) THEN 6
				ELSE 0
			END
		) AS metastatic_solid_tumor,
		-- //ANCHOR - aids/hiv
		MAX (
			CASE
				WHEN tt.pasthistorypath = 'notes/Progress Notes/Past History/Organ Systems/Infectious Disease (R)/AIDS/AIDS' THEN 6
				ELSE 0
			END
		) AS aids,
		-- //ANCHOR - age
		CASE
			WHEN pt.age LIKE '>%89' THEN 5
			WHEN pt.age LIKE '' THEN 0
			WHEN CAST(pt.age AS numeric) BETWEEN 80 AND 89 THEN 4
			WHEN CAST(pt.age AS numeric) BETWEEN 70 AND 79 THEN 3
			WHEN CAST(pt.age AS numeric) BETWEEN 60 AND 69 THEN 2
			WHEN CAST(pt.age AS numeric) BETWEEN 50 AND 59 THEN 1
			ELSE 0
		END AS age
	FROM icu.patient pt
		LEFT JOIN icu.pasthistory tt ON pt.patientunitstayid = tt.patientunitstayid
	GROUP BY pt.patientunitstayid
)
-- //ANCHOR - total
SELECT patientunitstayid,
	cerebrovascular_disease,
	paraplegia,
	dementia,
	myocardial_infarct,
	congestive_heart_failure,
	peripheral_vascular_disease,
	chronic_pulmonary_disease,
	rheumatic_disease,
	peptic_ulcer_disease,
	mild_liver_disease,
	severe_liver_disease,
	renal_disease,
	diabetes,
	(cancer + lymphoma +lymphoma) AS malignant_cancer,
	metastatic_solid_tumor,
	aids,
	age,
	(cerebrovascular_disease
	+ paraplegia
	+ dementia
	+ myocardial_infarct
	+ congestive_heart_failure
	+ peripheral_vascular_disease
	+ chronic_pulmonary_disease
	+ rheumatic_disease
	+ peptic_ulcer_disease
	+ mild_liver_disease
	+ severe_liver_disease
	+ renal_disease
	+ diabetes
	+ (cancer + lymphoma +lymphoma) -- malignant_cancer
	+ metastatic_solid_tumor
	+ aids
	+ age) AS charlson
FROM vw0
ORDER BY vw0.patientunitstayid;