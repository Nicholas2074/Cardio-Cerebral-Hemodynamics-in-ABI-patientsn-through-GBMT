# 环境

Ubuntu 20.04.6 LTS

psql (12.17 (Ubuntu 12.17-0ubuntu0.20.04.1))

## 配置继承自mimic

### 下载官方库

```
git clone https://github.com/MIT-LCP/mimic-code.git
```

### 下载数据集

```
wget -r -N -c -np --user nicholas2074 --ask-password https://physionet.org/files/mimiciv/3.0/
```

### 创建数据库

```
create database mimiciv30 owner nicholas;
\q
```

### 切换到代码所在文件夹

### 创建模式及表格

- create.sql

```
----------------------
-- Creating schemas --
----------------------

DROP SCHEMA IF EXISTS mimiciv_hosp CASCADE;
CREATE SCHEMA mimiciv_hosp;
DROP SCHEMA IF EXISTS mimiciv_icu CASCADE;
CREATE SCHEMA mimiciv_icu;
DROP SCHEMA IF EXISTS mimiciv_derived CASCADE;
CREATE SCHEMA mimiciv_derived;
```

- 删除其中的mimiciv_derived，不创建mimiciv_derived这个schema

```
DROP SCHEMA IF EXISTS mimiciv_derived CASCADE;
CREATE SCHEMA mimiciv_derived;
```

- 同时修改  language VARCHAR(10),为  language VARCHAR(30),

```
DROP TABLE IF EXISTS mimiciv_hosp.admissions;
CREATE TABLE mimiciv_hosp.admissions
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  admittime TIMESTAMP NOT NULL,
  dischtime TIMESTAMP,
  deathtime TIMESTAMP,
  admission_type VARCHAR(40) NOT NULL,
  admit_provider_id VARCHAR(10),
  admission_location VARCHAR(60),
  discharge_location VARCHAR(60),
  insurance VARCHAR(255),
  language VARCHAR(10),
  marital_status VARCHAR(30),
  race VARCHAR(80),
  edregtime TIMESTAMP,
  edouttime TIMESTAMP,
  hospital_expire_flag SMALLINT
);
```

```
psql -d mimiciv30 -f create.sql
```

### 载入数据集

```
psql -d mimiciv30 -v ON_ERROR_STOP=1 -f load_gz.sql
```

```
SET
COPY 431231
COPY 89200
COPY 4756326
...
```

### 添加约束

```
psql -d mimiciv30 -v ON_ERROR_STOP=1 -f constraint.sql
```

- error !!!

```
psql:constraint.sql:203: NOTICE:  constraint "diagnoses_icd_patients_fk" of relation "diagnoses_icd" does not exist, skipping
ALTER TABLE
psql:constraint.sql:207: ERROR:  insert or update on table "diagnoses_icd" violates foreign key constraint "diagnoses_icd_patients_fk"
DETAIL:  Key (subject_id)=(11404231) is not present in table "patients".
```

### 添加索引

```
psql -d mimiciv30 -v ON_ERROR_STOP=1 -f index.sql
```

### 校验数据

- 3.0中新增了2020-2022年的数据，但是validate.sql文件没有更新，所以校验失败

```
psql -d mimiciv30 -f validate.sql
```

```
        tbl         | expected_count | observed_count | row_count_check 
--------------------+----------------+----------------+-----------------
 admissions         |         431231 |         546028 | FAILED
 chartevents        |      313645063 |      432997491 | FAILED
 datetimeevents     |        7112999 |        9979761 | FAILED
 d_hcpcs            |          89200 |          89208 | FAILED
 diagnoses_icd      |        4756326 |        6364520 | FAILED
 d_icd_diagnoses    |         109775 |         112107 | FAILED
 d_icd_procedures   |          85257 |          86423 | FAILED
 d_items            |           4014 |           4095 | FAILED
 d_labitems         |           1622 |           1650 | FAILED
 drgcodes           |         604377 |         761860 | FAILED
 emar               |       26850359 |       42808593 | FAILED
 emar_detail        |       54744789 |       87371064 | FAILED
 hcpcsevents        |         150771 |         186074 | FAILED
 icustays           |          73181 |          94458 | FAILED
 inputevents        |        8978893 |       10953713 | FAILED
 labevents          |      118171367 |      158478383 | FAILED
 microbiologyevents |        3228713 |        3988224 | FAILED
 omr                |        6439169 |        7753027 | FAILED
 outputevents       |        4234967 |        5359395 | FAILED
 patients           |         299712 |         364627 | FAILED
 pharmacy           |       13584514 |       17847567 | FAILED
 poe                |       39366291 |       52212109 | FAILED
 poe_detail         |        3879418 |        8504982 | FAILED
 prescriptions      |       15416708 |       20292611 | FAILED
 procedureevents    |         696092 |         808706 | FAILED
 procedures_icd     |         669186 |         859655 | FAILED
 services           |         468029 |         593071 | FAILED
 transfers          |        1890972 |        2413589 | FAILED
(28 rows)
```

### 修改模式名称

```
ALTER SCHEMA mimiciv_hosp RENAME TO hosp;
ALTER SCHEMA mimiciv_icu RENAME TO icu;
```
