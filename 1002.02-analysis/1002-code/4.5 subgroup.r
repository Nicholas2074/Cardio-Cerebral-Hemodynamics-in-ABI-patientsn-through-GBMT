# //SECTION - multiglm

df1 <- merge(varsImp, mortality, by = "icuid", all = FALSE)
df2 <- merge(df1, gcs[, c(1, 3)], by = "icuid", all = FALSE)
df3 <- merge(df2, gcs[, c(1, 4)], by = "icuid", all = FALSE)

dfSubGroup <- df3

# regroup
dfSubGroup$group <- ifelse(dfSubGroup$group == 4, 1, 0)

# factor
summary(dfMor$age)

dfSubGroup$age <- ifelse(dfSubGroup$age < 56, 1,
    ifelse(dfSubGroup$age < 71, 2, 3)
)

summary(dfMor$bmi)

dfSubGroup$bmi <- ifelse(dfSubGroup$bmi < 27.4, 1,
    ifelse(dfSubGroup$bmi < 31.2, 2, 3)
)

# numeric
dfSubGroup$race <- as.numeric(dfSubGroup$race)

subNames <- c(
    "age",
    "gender",
    "bmi",
    # "gcs",
    "hypertension",
    "cerebrovascular_disease",
    "diabetes",
    "craniotomy",
    "ventriculostomy"
)

dfSubGroup[subNames] <- lapply(dfSubGroup[subNames], as.factor)

# //ANCHOR - hospMortality

# install.packages("jstable")

library(jstable)

resMor <- TableSubgroupMultiGLM(
    formula = hospMortality ~ group,
    var_subgroups = subNames,
    data = dfSubGroup,
    family = "binomial"
)

print(resMor)

resMor <- resMor[, c(
    "Variable", "Count", "OR", "Lower", "Upper", "P value", "P for interaction"
)]

resMor$" " <- paste(rep(" ", nrow(resMor)), collapse = " ")

resMor[, 2:7] <- lapply(resMor[, 2:7], as.numeric)

resMor[, c(2, 6, 7)][is.na(resMor[, c(2, 6, 7)])] <- " "

# //ANCHOR - disgcs

library(jstable)

resDis <- TableSubgroupMultiGLM(
    formula = disgcs ~ group,
    var_subgroups = subNames,
    data = dfSubGroup,
    family = "binomial"
)

print(resDis)

resDis <- resDis[, c(
    "Variable", "Count", "OR", "Lower", "Upper", "P value", "P for interaction"
)]

resDis$" " <- paste(rep(" ", nrow(resDis)), collapse = " ")

resDis[, 2:7] <- lapply(resDis[, 2:7], as.numeric)

resDis[, c(2, 6, 7)][is.na(resDis[, c(2, 6, 7)])] <- " "

# //ANCHOR - devgcs

library(jstable)

resDev <- TableSubgroupMultiGLM(
    formula = devgcs ~ group,
    var_subgroups = subNames,
    data = dfSubGroup,
    family = "binomial"
)

print(resDev)

resDev <- resDev[, c(
    "Variable", "Count", "OR", "Lower", "Upper", "P value", "P for interaction"
)]

resDev$" " <- paste(rep(" ", nrow(resDev)), collapse = " ")

resDev[, 2:7] <- lapply(resDev[, 2:7], as.numeric)

resDev[, c(2, 6, 7)][is.na(resDev[, c(2, 6, 7)])] <- " "

# //!SECTION

# //SECTION - forestplot

# //ANCHOR - hospMortality

# install.packages("forestploter")

library(forestploter)

forestMor <- forest(
    data = resMor[, c(1, 2, 8, 6, 7)],
    lower = resMor$Lower,
    upper = resMor$Upper,
    est = resMor$OR,
    ci_column = 3,
    ref_line = 1,
    xlim = c(0, 10),
    title = "Subgroup analysis (in-hospital mortality)",
)

print(forestMor)

# //ANCHOR - disgcs

library(forestploter)

forestDis <- forest(
    data = resDis[, c(1, 2, 8, 6, 7)],
    lower = resDis$Lower,
    upper = resDis$Upper,
    est = resDis$OR,
    ci_column = 3,
    ref_line = 1,
    xlim = c(0, 10),
    title = "Subgroup analysis (discharge GCS)",
)

print(forestDis)

# //ANCHOR - devgcs

library(forestploter)

forestDev <- forest(
    data = resDev[, c(1, 2, 8, 6, 7)],
    lower = resDev$Lower,
    upper = resDev$Upper,
    est = resDev$OR,
    ci_column = 3,
    ref_line = 1,
    xlim = c(0, 10),
    title = "Subgroup analysis (GCS difference)",
)

print(forestDev)

# //!SECTION