-- //SECTION - multitraj
-- time interval: 5 mins
-- //ANCHOR - icp
COPY (
    WITH vw0 AS (
        SELECT tt.stay_id,
            ROUND(tt.chartoffset / 5) AS interval,
            -- "/" results in an integer
            tt.icp
        FROM public.unionid_0 pt
            INNER JOIN public.dmin_icp tt ON pt.stay_id = tt.stay_id
        WHERE tt.chartoffset >= 0
            AND tt.chartoffset < 7200
    )
    SELECT stay_id,
        interval,
        ROUND(AVG(icp)) AS icp
    FROM vw0
    GROUP BY stay_id,
        interval
    ORDER BY stay_id,
        interval
) TO '/tmp/micp.csv' WITH CSV HEADER;
-- //ANCHOR - bp
COPY (
    WITH vw0 AS (
        SELECT tt.stay_id,
            ROUND(tt.chartoffset / 5) AS interval,
            -- "/" results in an integer
            tt.isbp,
            tt.idbp,
            tt.nisbp,
            tt.nidbp
        FROM public.unionid_0 pt
            INNER JOIN public.dmin_bp tt ON pt.stay_id = tt.stay_id
        WHERE tt.chartoffset >= 0
            AND tt.chartoffset < 7200
    )
    SELECT stay_id,
        interval,
        ROUND(AVG(isbp)) AS isbp,
        ROUND(AVG(idbp)) AS idbp,
        ROUND(AVG(nisbp)) AS nisbp,
        ROUND(AVG(nidbp)) AS nidbp
    FROM vw0
    GROUP BY stay_id,
        interval
    ORDER BY stay_id,
        interval
) TO '/tmp/mbp.csv' WITH CSV HEADER;
-- //ANCHOR - hr
COPY (
    WITH vw0 AS (
        SELECT tt.stay_id,
            ROUND(tt.chartoffset / 5) AS interval,
            -- "/" results in an integer
            tt.hr
        FROM public.unionid_0 pt
            INNER JOIN public.dmin_hr tt ON pt.stay_id = tt.stay_id
        WHERE tt.chartoffset >= 0
            AND tt.chartoffset < 7200
    )
    SELECT stay_id,
        interval,
        ROUND(AVG(hr)) AS hr
    FROM vw0
    GROUP BY stay_id,
        interval
    ORDER BY stay_id,
        interval
) TO '/tmp/mhr.csv' WITH CSV HEADER;
-- //!SECTION
-- //SECTION - outcome
-- //ANCHOR - hosp_mortality
COPY (
    SELECT tt.stay_id,
        tt.hosp_mortality
    FROM public.unionid_0 pt
        INNER JOIN public.feat_patient tt ON pt.stay_id = tt.stay_id
    ORDER BY stay_id
) TO '/tmp/mmortality.csv' WITH CSV HEADER;
-- //ANCHOR - gcs
COPY (
    SELECT tt.stay_id,
        MAX(tt.adm_gcs) AS adm_gcs,
        MAX(tt.dis_gcs) AS dis_gcs,
        (MAX(tt.dis_gcs) - MAX(tt.adm_gcs)) AS dev_gcs
    FROM public.unionid_0 pt
        INNER JOIN public.dmin_gcs tt ON pt.stay_id = tt.stay_id
    GROUP BY tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mdev_gcs.csv' WITH CSV HEADER;
-- //!SECTION
-- //SECTION - tyg
-- //ANCHOR - tyg
COPY (
    WITH glu AS (
        WITH t0 AS (
            SELECT pt.stay_id,
                ROUND(
                    EXTRACT(
                        EPOCH
                        FROM (tt.charttime - pt.intime)
                    ) / 60
                ) AS chartoffset,
                tt.glucose
            FROM public.unionid_0 pt
                INNER JOIN public.repo_chemistry tt ON pt.hadm_id = tt.hadm_id
            WHERE tt.glucose > 0
        )
        SELECT stay_id,
            MIN(glucose) AS glucose
        FROM t0
        WHERE chartoffset >= 0
            AND chartoffset <= 1440
        GROUP BY stay_id
    ),
    tg AS (
        WITH t0 AS (
            SELECT pt.stay_id,
                ROUND(
                    EXTRACT(
                        EPOCH
                        FROM (tt.charttime - pt.intime)
                    ) / 60
                ) AS chartoffset,
                tt.tg
            FROM public.unionid_0 pt
                INNER JOIN public.repo_lipid tt ON pt.hadm_id = tt.hadm_id
            WHERE tt.tg > 0
        )
        SELECT stay_id,
            FIRST_VALUE(tg) OVER (
                PARTITION BY stay_id
                ORDER BY chartoffset ASC
            ) AS tg
        FROM t0
        WHERE chartoffset >= -1440
            AND chartoffset <= 1440
    )
    SELECT glu.stay_id,
        ROUND(CAST(LOG(glu.glucose * tg.tg / 2) AS numeric), 2) AS tyg
    FROM glu
        INNER JOIN tg ON glu.stay_id = tg.stay_id
) TO '/tmp/mtyg.csv' WITH CSV HEADER;
-- //!SECTION
-- //SECTION - feature
-- //ANCHOR - patient
COPY (
    SELECT tt.stay_id,
        tt.age,
        tt.gender,
        tt.bmi,
        tt.race,
        tt.icu_los_hours,
        tt.hosp_los_hours
    FROM public.unionid_0 pt
        INNER JOIN public.feat_patient tt ON pt.stay_id = tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mpatient.csv' WITH CSV HEADER;
-- //ANCHOR - diagnosis
COPY (
    SELECT tt.* -- 1 represents having a disease.
    FROM public.unionid_0 pt
        INNER JOIN public.feat_diagnosis tt ON pt.stay_id = tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mdiagnosis.csv' WITH CSV HEADER;
-- //ANCHOR - score
COPY (
    SELECT tt.*
    FROM public.unionid_0 pt
        INNER JOIN public.feat_day1_score tt ON pt.stay_id = tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mscore.csv' WITH CSV HEADER;
-- //ANCHOR - surgery
COPY (
    SELECT tt.stay_id,
        MAX(tt.craniotomy) AS craniotomy,
        MAX(tt.ventriculostomy) AS ventriculostomy,
        MAX(tt.csfdrainage) AS csfdrainage
    FROM public.unionid_0 pt
        INNER JOIN public.feat_surgery tt ON pt.stay_id = tt.stay_id
    GROUP BY tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/msurgery.csv' WITH CSV HEADER;
-- //ANCHOR - drug
COPY (
    SELECT DISTINCT tt.stay_id,
        CASE
            WHEN MAX(tt.rate) > 0 THEN 1
            ELSE 0
        END AS hsaline
    FROM public.unionid_0 pt
        INNER JOIN public.dmin_hsaline tt ON pt.stay_id = tt.stay_id
    GROUP BY tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mhsaline.csv' WITH CSV HEADER;
COPY (
    SELECT DISTINCT tt.stay_id,
        CASE
            WHEN MAX(tt.rate) > 0 THEN 1
            ELSE 0
        END AS mannitol
    FROM public.unionid_0 pt
        INNER JOIN public.dmin_mannitol tt ON pt.stay_id = tt.stay_id
    GROUP BY tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mmannitol.csv' WITH CSV HEADER;
-- //ANCHOR - vital
COPY (
    SELECT tt.*
    FROM public.unionid_0 pt
        INNER JOIN public.feat_day1_vital tt ON pt.stay_id = tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mvital.csv' WITH CSV HEADER;
-- //ANCHOR - lab
COPY (
    SELECT tt.*
    FROM public.unionid_0 pt
        INNER JOIN public.feat_day1_lab tt ON pt.stay_id = tt.stay_id
    ORDER BY tt.stay_id
) TO '/tmp/mlab.csv' WITH CSV HEADER;