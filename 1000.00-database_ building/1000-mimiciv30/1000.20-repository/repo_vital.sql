DROP TABLE IF EXISTS repo_vital;
CREATE TABLE repo_vital AS
-- This query pivots the vital signs for the entire patient stay.
-- The result is a tabler with stay_id, charttime, and various
-- vital signs, with one row per charted time.
SELECT subject_id,
    stay_id,
    charttime,
    CAST(
        AVG(
            CASE
                WHEN itemid IN (220045)
                AND valuenum > 0
                AND valuenum < 300 THEN valuenum
            END
        ) AS NUMERIC
    ) AS heartrate,
    CAST(
        AVG(
            CASE
                WHEN itemid IN (220210, 224690)
                AND valuenum > 0
                AND valuenum < 70 THEN valuenum
            END
        ) AS NUMERIC
    ) AS resprate,
    CAST(
        AVG(
            CASE
                WHEN itemid IN (220277)
                AND valuenum > 0
                AND valuenum <= 100 THEN valuenum
            END
        ) AS NUMERIC
    ) AS spo2,
    CAST(
        AVG(
            CASE
                WHEN itemid = 220179
                AND valuenum > 0
                AND valuenum < 400 THEN valuenum
            END
        ) AS NUMERIC
    ) AS nisbp,
    CAST(
        AVG(
            CASE
                WHEN itemid = 220180
                AND valuenum > 0
                AND valuenum < 300 THEN valuenum
            END
        ) AS NUMERIC
    ) AS nidbp,
    CAST(
        AVG(
            CASE
                WHEN itemid = 220181
                AND valuenum > 0
                AND valuenum < 300 THEN valuenum
            END
        ) AS NUMERIC
    ) AS nimbp,
    CAST(
        AVG(
            CASE
                WHEN itemid IN (220050, 225309) -- //FIXME - bug in official code (fixed)
                AND valuenum > 0
                AND valuenum < 400 THEN valuenum
            END
        ) AS NUMERIC
    ) AS isbp,
    CAST(
        AVG(
            CASE
                WHEN itemid IN (220051, 225310) -- //FIXME - bug in official code (fixed)
                AND valuenum > 0
                AND valuenum < 300 THEN valuenum
            END
        ) AS NUMERIC
    ) AS idbp,
    CAST(
        AVG(
            CASE
                WHEN itemid IN (220052, 225312) -- //FIXME - bug in official code (fixed)
                AND valuenum > 0
                AND valuenum < 300 THEN valuenum
            END
        ) AS NUMERIC
    ) AS imbp,
    ROUND(
        CAST(
            AVG(
                CASE
                    -- converted to degC in valuenum call
                    WHEN itemid IN (223761)
                    AND valuenum > 70
                    AND valuenum < 120 THEN (valuenum - 32) / 1.8 -- already in degC, no conversion necessary
                    WHEN itemid IN (223762)
                    AND valuenum > 10
                    AND valuenum < 50 THEN valuenum
                END
            ) AS NUMERIC
        ),
        2
    ) AS temperature,
    MAX(
        CASE
            WHEN itemid = 224642 THEN value
        END
    ) AS temperature_site -- AVG(
    -- 	CASE
    -- 		WHEN itemid IN (225664, 220621, 226537)
    -- 		AND valuenum > 0 THEN valuenum
    -- 	END
    -- ) AS glucose
FROM icu.chartevents
WHERE stay_id IS NOT NULL
    AND itemid IN (
        220045,
        -- Heart Rate
        220210,
        -- Respiratory Rate
        224690,
        -- Respiratory Rate (Total)
        220277,
        -- SPO2, peripheral
        220179,
        -- Non Invasive Blood Pressure systolic
        220180,
        -- Non Invasive Blood Pressure diastolic
        220181,
        -- Non Invasive Blood Pressure mean
        225309,
        -- ART BP Systolic
        225310,
        -- ART BP Diastolic
        225312,
        -- ART BP Mean
        220050,
        -- Arterial Blood Pressure systolic
        220051,
        -- Arterial Blood Pressure diastolic
        220052,
        -- Arterial Blood Pressure mean
        -- 226329, -- Blood Temperature CCO (C)
        223762,
        -- "Temperature Celsius"
        223761,
        -- "Temperature Fahrenheit"
        224642 -- Temperature Site
        -- GLUCOSE, both lab and fingerstick(dropped)
        -- 225664, -- Glucose finger stick
        -- 220621, -- Glucose (serum)
        -- 226537, -- Glucose (whole blood)
    )
GROUP BY subject_id,
    stay_id,
    charttime;