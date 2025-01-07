## 环境

Ubuntu 20.04.6 LTS

psql (12.17 (Ubuntu 12.17-0ubuntu0.20.04.1))

## 配置继承自mimic

### 下载官方库

```
git clone https://github.com/MIT-LCP/eicu-code.git
```

### 下载数据集

```
wget -r -N -c -np --user nicholas2074 --ask-password https://physionet.org/files/eicu-crd/2.0/
```

### 创建数据库

```
psql
```

```
create database eicu20 owner nicholas;
```

### 创建模式

```
\c eicu20;
create schema icu;
\q
```

### 切换到代码所在文件夹

### 创建表格

```
psql -d eicu20 -f postgres_create_tables.sql
```

### 载入数据集

```
psql -d eicu20 -v ON_ERROR_STOP=1 -f postgres_load_data_gz.sql
```

### 添加约束

```
psql -d eicu20 -v ON_ERROR_STOP=1 -f postgres_add_constraints.sql
```

### 添加索引

```
psql -d eicu20 -v ON_ERROR_STOP=1 -f postgres_add_indexes.sql
```

### 校验数据

```
psql -d eicu20 -f postgres_checks.sql
```
