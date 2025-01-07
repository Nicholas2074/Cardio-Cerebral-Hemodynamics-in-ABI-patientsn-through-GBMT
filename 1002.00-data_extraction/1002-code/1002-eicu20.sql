-- //SECTION - multitraj
-- time interval: 5 mins
-- //ANCHOR - icp
COPY (
    WITH vw0 AS (
        SELECT tt.patientunitstayid,
            (tt.chartoffset / 5) AS interval,
            -- "/" results in an integer
            tt.icp
        FROM public.unionid_0 pt
            INNER JOIN public.dmin_icp tt ON pt.patientunitstayid = tt.patientunitstayid
        WHERE tt.chartoffset >= 0
            AND tt.chartoffset < 7200
    )
    SELECT patientunitstayid,
        interval,
        ROUND(AVG(icp)) AS icp
    FROM vw0
    GROUP BY patientunitstayid,
        interval
    ORDER BY patientunitstayid,
        interval
) TO '/tmp/eicp.csv' WITH CSV HEADER;
-- //ANCHOR - bp
COPY (
    WITH vw0 AS (
        SELECT tt.patientunitstayid,
            (tt.chartoffset / 5) AS interval,
            -- "/" results in an integer
            tt.isbp,
            tt.idbp,
            tt.nisbp,
            tt.nidbp
        FROM public.unionid_0 pt
            INNER JOIN public.dmin_bp tt ON pt.patientunitstayid = tt.patientunitstayid
        WHERE tt.chartoffset >= 0
            AND tt.chartoffset < 7200
    )
    SELECT patientunitstayid,
        interval,
        ROUND(AVG(isbp)) AS isbp,
        ROUND(AVG(idbp)) AS idbp,
        ROUND(AVG(nisbp)) AS nisbp,
        ROUND(AVG(nidbp)) AS nidbp
    FROM vw0
    GROUP BY patientunitstayid,
        interval
    ORDER BY patientunitstayid,
        interval
) TO '/tmp/ebp.csv' WITH CSV HEADER;
-- //ANCHOR - hr
COPY (
    WITH vw0 AS (
        SELECT tt.patientunitstayid,
            (tt.chartoffset / 5) AS interval,
            -- "/" results in an integer
            tt.hr
        FROM public.unionid_0 pt
            INNER JOIN public.dmin_hr tt ON pt.patientunitstayid = tt.patientunitstayid
        WHERE tt.chartoffset >= 0
            AND tt.chartoffset < 7200
    )
    SELECT patientunitstayid,
        interval,
        ROUND(AVG(hr)) AS hr
    FROM vw0
    GROUP BY patientunitstayid,
        interval
    ORDER BY patientunitstayid,
        interval
) TO '/tmp/ehr.csv' WITH CSV HEADER;
-- //!SECTION
-- //SECTION - outcome
-- //ANCHOR - hosp_mortality
COPY (
    SELECT tt.patientunitstayid,
        tt.hosp_mortality
    FROM public.unionid_0 pt
        INNER JOIN public.feat_patient tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY patientunitstayid
) TO '/tmp/emortality.csv' WITH CSV HEADER;
-- //ANCHOR - gcs
COPY (
    SELECT tt.patientunitstayid,
        MAX(tt.adm_gcs) AS adm_gcs,
        MAX(tt.dis_gcs) AS dis_gcs,
        (MAX(tt.dis_gcs) - MAX(tt.adm_gcs)) AS dev_gcs
    FROM public.unionid_0 pt
        INNER JOIN public.dmin_gcs tt ON pt.patientunitstayid = tt.patientunitstayid
    GROUP BY tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/edev_gcs.csv' WITH CSV HEADER;
-- //!SECTION
-- //SECTION - tyg
-- //ANCHOR - tyg
COPY (
    WITH glu AS (
        WITH t0 AS (
            SELECT pt.patientunitstayid,
                tt.chartoffset,
                tt.glucose
            FROM public.unionid_0 pt
                INNER JOIN public.repo_chemistry tt ON pt.patientunitstayid = tt.patientunitstayid
            WHERE tt.glucose > 0
        )
        SELECT patientunitstayid,
            MIN(glucose) AS glucose
        FROM t0
        WHERE chartoffset >= 0
            AND chartoffset <= 1440
        GROUP BY patientunitstayid
    ),
    tg AS (
        WITH t0 AS (
            SELECT pt.patientunitstayid,
                tt.chartoffset,
                tt.tg
            FROM public.unionid_0 pt
                INNER JOIN public.repo_lipid tt ON pt.patientunitstayid = tt.patientunitstayid
            WHERE tt.tg > 0
        )
        SELECT patientunitstayid,
            FIRST_VALUE(tg) OVER (
                PARTITION BY patientunitstayid
                ORDER BY chartoffset ASC
            ) AS tg
        FROM t0
        WHERE chartoffset >= -1440
            AND chartoffset <= 1440
    )
    SELECT glu.patientunitstayid,
        ROUND(LOG(glu.glucose * tg.tg / 2), 2) AS tyg
    FROM glu
        INNER JOIN tg ON glu.patientunitstayid = tg.patientunitstayid
) TO '/tmp/etyg.csv' WITH CSV HEADER;
-- //!SECTION
-- //SECTION - feature
-- //ANCHOR - patient
COPY (
    SELECT tt.patientunitstayid,
        tt.age,
        tt.gender,
        tt.bmi,
        tt.race,
        tt.icu_los_hours,
        tt.hosp_los_hours
    FROM public.unionid_0 pt
        INNER JOIN public.feat_patient tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/epatient.csv' WITH CSV HEADER;
-- //ANCHOR - diagnosis
COPY (
    SELECT tt.* -- 1 represents having a disease.
    FROM public.unionid_0 pt
        INNER JOIN public.feat_diagnosis tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/ediagnosis.csv' WITH CSV HEADER;
-- //ANCHOR - score
COPY (
    SELECT tt.*
    FROM public.unionid_0 pt
        INNER JOIN public.feat_day1_score tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/escore.csv' WITH CSV HEADER;
-- //ANCHOR - surgery
COPY (
    SELECT tt.patientunitstayid,
        MAX(tt.craniotomy) AS craniotomy,
        MAX(tt.ventriculostomy) AS ventriculostomy,
        MAX(tt.csfdrainage) AS csfdrainage
    FROM public.unionid_0 pt
        INNER JOIN public.feat_surgery tt ON pt.patientunitstayid = tt.patientunitstayid
    GROUP BY tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/esurgery.csv' WITH CSV HEADER;
-- //ANCHOR - drug
COPY (
    SELECT DISTINCT tt.patientunitstayid,
        CASE
            WHEN tt.drugrate <> '0' THEN 1
            ELSE 0
        END AS hsaline
    FROM public.unionid_0 pt
        INNER JOIN public.dmin_hsaline tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/ehsaline.csv' WITH CSV HEADER;
COPY (
    SELECT DISTINCT tt.patientunitstayid,
        CASE
            WHEN tt.drugrate <> '0' THEN 1
            ELSE 0
        END AS mannitol
    FROM public.unionid_0 pt
        INNER JOIN public.dmin_mannitol tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/emannitol.csv' WITH CSV HEADER;
-- //ANCHOR - vital
COPY (
    SELECT tt.*
    FROM public.unionid_0 pt
        INNER JOIN public.feat_day1_vital tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/evital.csv' WITH CSV HEADER;
-- //ANCHOR - lab
COPY (
    SELECT tt.*
    FROM public.unionid_0 pt
        INNER JOIN public.feat_day1_lab tt ON pt.patientunitstayid = tt.patientunitstayid
    ORDER BY tt.patientunitstayid
) TO '/tmp/elab.csv' WITH CSV HEADER;