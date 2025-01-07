-- //ANCHOR - mannitol
DROP TABLE IF EXISTS dmin_mannitol;
CREATE TABLE dmin_mannitol AS
SELECT DISTINCT stay_id,
    linkorderid,
    rate,
    amount,
    starttime,
    endtime
FROM icu.inputevents
WHERE itemid = 227531;
-- mannitol
-- //ANCHOR - hypertonic saline
DROP TABLE IF EXISTS dmin_hsaline;
CREATE TABLE dmin_hsaline AS
SELECT DISTINCT stay_id,
    linkorderid,
    rate,
    amount,
    starttime,
    endtime
FROM icu.inputevents
WHERE itemid = 225161;
-- hypertonic saline