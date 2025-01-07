# //SECTION - glm

# //ANCHOR - hospMortality

# cor
dfCorMor <- dfCovMor

corMor <- cor(dfCorMor[, -1:-2])

# heatmap(corMor)

# glm
print(names(dfCovMor))

logMorAdjusted <- glm(
    hospMortality ~
        group +
        age +
        gender +
        bmi +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfCovMor
)

# summary
summary(logMorAdjusted)

pMorAdjusted <- coef(summary(logMorAdjusted))[, "Pr(>|z|)"]
pMorAdjusted

orMorAdjusted <- exp(coef(logMorAdjusted))
orMorAdjusted

ciMorAdjusted <- exp(confint(logMorAdjusted))
ciMorAdjusted

# //ANCHOR - disgcs

# cor
dfCorDis <- dfCovDis

dfCorDis$gcs <- as.numeric(dfCorDis$gcs)

corDis <- cor(dfCorDis[, -1:-2])

# heatmap(corDis)

# glm
print(names(dfCovDis))

logDisAdjusted <- glm(
    disgcs ~
        group +
        age +
        gender +
        bmi +
        gcs +
        magnesium +
        resprate_avg +
        sodium +
        temperature_cv,
    family = binomial,
    data = dfCovDis
)

# summary
summary(logDisAdjusted)

pDisAdjusted <- coef(summary(logDisAdjusted))[, "Pr(>|z|)"]
pDisAdjusted

orDisAdjusted <- exp(coef(logDisAdjusted))
orDisAdjusted

ciDisAdjusted <- exp(confint(logDisAdjusted))
ciDisAdjusted

# //ANCHOR - devgcs

# cor
dfCorDev <- dfCovDev

dfCorDev$gcs <- as.numeric(dfCorDev$gcs)

corDev <- cor(dfCorDev[, -1:-2])

# heatmap(corDev)

# glm
print(names(dfCovDev))

logDevAdjusted <- glm(
    devgcs ~
        group +
        age +
        gender +
        bmi +
        gcs +
        mch +
        ptt +
        # renal_disease +
        sodium,
    family = binomial,
    data = dfCovDev
)

# summary
summary(logDevAdjusted)

pDevAdjusted <- coef(summary(logDevAdjusted))[, "Pr(>|z|)"]
pDevAdjusted

orDevAdjusted <- exp(coef(logDevAdjusted))
orDevAdjusted

ciDevAdjusted <- exp(confint(logDevAdjusted))
ciDevAdjusted

# //!SECTION

# //SECTION - forestplot

# //ANCHOR - hospMortality

# calculate
library(tidyverse)

dfForestMorAdjusted <- data.frame(
    "Variable" = names(pMorAdjusted),
    "P value" = pMorAdjusted,
    "OR" = orMorAdjusted,
    "Lower" = ciMorAdjusted[, 1],
    "Upper" = ciMorAdjusted[, 2],
    row.names = NULL
)

dfForestMorAdjusted <- dfForestMorAdjusted[-1, ]

dfForestMorAdjusted[, -1] <- round(dfForestMorAdjusted[, -1], 3)

dfForestMorAdjusted <- dfForestMorAdjusted %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

rowNames <- data.frame(
    "Variable" = "Variable",
    "P value" = "P value",
    "OR" = "OR",
    "Lower" = "Lower",
    "Upper" = "Upper",
    "ORCI" = "OR(95%CI)",
    row.names = NULL
)

dfForestMorAdjusted <- rbind(rowNames, dfForestMorAdjusted)

dfForestMorAdjusted[, c("OR", "Lower", "Upper")] <- apply(dfForestMorAdjusted[, c("OR", "Lower", "Upper")], 2, as.numeric)

print(dfForestMorAdjusted)

# plot
library(forestplot)

forestMorLogAdjusted <- forestplot(
    labeltext = as.matrix(dfForestMorAdjusted[, c(1, 2, 6)]),
    mean = dfForestMorAdjusted$OR,
    lower = dfForestMorAdjusted$Lower,
    upper = dfForestMorAdjusted$Upper,
    zero = 1,
    boxsize = 0.2,
    lwd.zero = 2,
    lwd.ci = 2,
    lwd.xaxis = 1.5,
    txt_gp = fpTxtGp(
        ticks = gpar(cex = 1.5),
        xlab = gpar(cex = 1.5),
        cex = 1.5
    ),
    col = fpColors(
        box = "#458B00",
        summary = "#8B008B",
        lines = "black",
        zero = "#7AC5CD"
    ),
    graph.pos = 2,
    xlab = "Odds Ratio",
    title = "Adjusted model (in-hospital mortality)",
)

print(forestMorLogAdjusted)

# //ANCHOR - disgcs

# calculate
library(tidyverse)

dfForestDisAdjusted <- data.frame(
    "Variable" = names(pDisAdjusted),
    "P value" = pDisAdjusted,
    "OR" = orDisAdjusted,
    "Lower" = ciDisAdjusted[, 1],
    "Upper" = ciDisAdjusted[, 2],
    row.names = NULL
)

dfForestDisAdjusted <- dfForestDisAdjusted[-1, ]

dfForestDisAdjusted[, -1] <- round(dfForestDisAdjusted[, -1], 3)

dfForestDisAdjusted <- dfForestDisAdjusted %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

rowNames <- data.frame(
    "Variable" = "Variable",
    "P value" = "P value",
    "OR" = "OR",
    "Lower" = "Lower",
    "Upper" = "Upper",
    "ORCI" = "OR(95%CI)",
    row.names = NULL
)

dfForestDisAdjusted <- rbind(rowNames, dfForestDisAdjusted)

dfForestDisAdjusted[, c("OR", "Lower", "Upper")] <- apply(dfForestDisAdjusted[, c("OR", "Lower", "Upper")], 2, as.numeric)

print(dfForestDisAdjusted)

# plot
library(forestplot)

forestDisLogAdjusted <- forestplot(
    labeltext = as.matrix(dfForestDisAdjusted[, c(1, 2, 6)]),
    mean = dfForestDisAdjusted$OR,
    lower = dfForestDisAdjusted$Lower,
    upper = dfForestDisAdjusted$Upper,
    zero = 1,
    boxsize = 0.2,
    lwd.zero = 2,
    lwd.ci = 2,
    lwd.xaxis = 1.5,
    txt_gp = fpTxtGp(
        ticks = gpar(cex = 1.5),
        xlab = gpar(cex = 1.5),
        cex = 1.5
    ),
    col = fpColors(
        box = "#458B00",
        summary = "#8B008B",
        lines = "black",
        zero = "#7AC5CD"
    ),
    graph.pos = 2,
    xlab = "Odds Ratio",
    title = "Adjusted model (discharge GCS)",
)

print(forestDisLogAdjusted)

# //ANCHOR - devgcs

# calculate
library(tidyverse)

dfForestDevAdjusted <- data.frame(
    "Variable" = names(pDevAdjusted),
    "P value" = pDevAdjusted,
    "OR" = orDevAdjusted,
    "Lower" = ciDevAdjusted[, 1],
    "Upper" = ciDevAdjusted[, 2],
    row.names = NULL
)

dfForestDevAdjusted <- dfForestDevAdjusted[-1, ]

dfForestDevAdjusted[, -1] <- round(dfForestDevAdjusted[, -1], 3)

dfForestDevAdjusted <- dfForestDevAdjusted %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

rowNames <- data.frame(
    "Variable" = "Variable",
    "P value" = "P value",
    "OR" = "OR",
    "Lower" = "Lower",
    "Upper" = "Upper",
    "ORCI" = "OR(95%CI)",
    row.names = NULL
)

dfForestDevAdjusted <- rbind(rowNames, dfForestDevAdjusted)

dfForestDevAdjusted[, c("OR", "Lower", "Upper")] <- apply(dfForestDevAdjusted[, c("OR", "Lower", "Upper")], 2, as.numeric)

print(dfForestDevAdjusted)

# plot
library(forestplot)

forestDevLogAdjusted <- forestplot(
    labeltext = as.matrix(dfForestDevAdjusted[, c(1, 2, 6)]),
    mean = dfForestDevAdjusted$OR,
    lower = dfForestDevAdjusted$Lower,
    upper = dfForestDevAdjusted$Upper,
    zero = 1,
    boxsize = 0.2,
    lwd.zero = 2,
    lwd.ci = 2,
    lwd.xaxis = 1.5,
    txt_gp = fpTxtGp(
        ticks = gpar(cex = 1.5),
        xlab = gpar(cex = 1.5),
        cex = 1.5
    ),
    col = fpColors(
        box = "#458B00",
        summary = "#8B008B",
        lines = "black",
        zero = "#7AC5CD"
    ),
    graph.pos = 2,
    xlab = "Odds Ratio",
    title = "Adjusted model (GCS difference)",
)

print(forestDevLogAdjusted)

# //!SECTION
