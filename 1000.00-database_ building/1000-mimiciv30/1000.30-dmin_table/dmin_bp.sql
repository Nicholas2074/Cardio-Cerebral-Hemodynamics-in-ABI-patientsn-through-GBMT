DROP TABLE IF EXISTS dmin_bp;
CREATE TABLE dmin_bp AS WITH bp AS (
    SELECT DISTINCT tt.stay_id,
        CAST(
            ROUND(
                EXTRACT(
                    EPOCH
                    FROM (tt.charttime - pt.intime)
                ) / 60
            ) AS INTEGER
        ) AS chartoffset,
        tt.isbp,
        tt.idbp,
        tt.nisbp,
        tt.nidbp
    FROM icu.icustays pt
        INNER JOIN public.repo_vital tt ON pt.stay_id = tt.stay_id
    WHERE tt.isbp > 0
        AND tt.idbp > 0
        AND tt.nisbp > 0
        AND tt.nidbp > 0
)
SELECT stay_id,
    chartoffset,
    ROUND(AVG(isbp::NUMERIC)) AS isbp,
    ROUND(AVG(idbp::NUMERIC)) AS idbp,
    ROUND(AVG(nisbp::NUMERIC)) AS nisbp,
    ROUND(AVG(nidbp::NUMERIC)) AS nidbp
FROM bp
GROUP BY stay_id,
    chartoffset
ORDER BY stay_id,
    chartoffset;