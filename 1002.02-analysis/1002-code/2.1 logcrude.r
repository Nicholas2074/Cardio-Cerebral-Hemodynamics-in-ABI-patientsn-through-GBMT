# //SECTION - glm

# //ANCHOR - hospMortality

logMorCrude <- glm(hospMortality ~ group, data = trajMor, family = binomial)

summary(logMorCrude)

pMorCrude <- coef(summary(logMorCrude))[, "Pr(>|z|)"]
pMorCrude

orMorCrude <- exp(coef(logMorCrude))
orMorCrude

ciMorCrude <- exp(confint(logMorCrude))
ciMorCrude

# //ANCHOR - disgcs

logDisCrude <- glm(disgcs ~ group, data = trajDis, family = binomial)

summary(logDisCrude)

pDisCrude <- coef(summary(logDisCrude))[, "Pr(>|z|)"]
pDisCrude

orDisCrude <- exp(coef(logDisCrude))
orDisCrude

ciDisCrude <- exp(confint(logDisCrude))
ciDisCrude

# //ANCHOR - devgcs

logDevCrude <- glm(devgcs ~ group, data = trajDev, family = binomial)

summary(logDevCrude)

pDevCrude <- coef(summary(logDevCrude))[, "Pr(>|z|)"]
pDevCrude

orDevCrude <- exp(coef(logDevCrude))
orDevCrude

ciDevCrude <- exp(confint(logDevCrude))
ciDevCrude

# //!SECTION

# //SECTION - forestplot

# //ANCHOR - hospMortality

library(tidyverse)

dfForestMorCrude <- data.frame(
    "Variable" = names(pMorCrude),
    "P value" = pMorCrude,
    "OR" = orMorCrude,
    "Lower" = ciMorCrude[, 1],
    "Upper" = ciMorCrude[, 2],
    row.names = NULL
)

dfForestMorCrude <- dfForestMorCrude[-1, ]

dfForestMorCrude[, -1] <- round(dfForestMorCrude[, -1], 3)

dfForestMorCrude <- dfForestMorCrude %>%
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

dfForestMorCrude <- rbind(rowNames, dfForestMorCrude)

dfForestMorCrude[, c("OR", "Lower", "Upper")] <- apply(dfForestMorCrude[, c("OR", "Lower", "Upper")], 2, as.numeric)

print(dfForestMorCrude)

# plot
library(forestplot)

forestMorLogCrude <- forestplot(
    labeltext = as.matrix(dfForestMorCrude[, c(1, 2, 6)]),
    mean = dfForestMorCrude$OR,
    lower = dfForestMorCrude$Lower,
    upper = dfForestMorCrude$Upper,
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
    title = "Crude model (in-hospital mortality)",
)

print(forestMorLogCrude)

# //ANCHOR - disgcs

library(tidyverse)

dfForestDisCrude <- data.frame(
    "Variable" = names(pDisCrude),
    "P value" = pDisCrude,
    "OR" = orDisCrude,
    "Lower" = ciDisCrude[, 1],
    "Upper" = ciDisCrude[, 2],
    row.names = NULL
)

dfForestDisCrude <- dfForestDisCrude[-1, ]

dfForestDisCrude[, -1] <- round(dfForestDisCrude[, -1], 3)

dfForestDisCrude <- dfForestDisCrude %>%
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

dfForestDisCrude <- rbind(rowNames, dfForestDisCrude)

dfForestDisCrude[, c("OR", "Lower", "Upper")] <- apply(dfForestDisCrude[, c("OR", "Lower", "Upper")], 2, as.numeric)

print(dfForestDisCrude)

# plot
library(forestplot)

forestDisLogCrude <- forestplot(
    labeltext = as.matrix(dfForestDisCrude[, c(1, 2, 6)]),
    mean = dfForestDisCrude$OR,
    lower = dfForestDisCrude$Lower,
    upper = dfForestDisCrude$Upper,
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
    title = "Crude model (discharge GCS)",
)

print(forestDisLogCrude)

# //ANCHOR - devgcs

# calculate
library(tidyverse)

dfForestDevCrude <- data.frame(
    "Variable" = names(pDevCrude),
    "P value" = pDevCrude,
    "OR" = orDevCrude,
    "Lower" = ciDevCrude[, 1],
    "Upper" = ciDevCrude[, 2],
    row.names = NULL
)

dfForestDevCrude <- dfForestDevCrude[-1, ]

dfForestDevCrude[, -1] <- round(dfForestDevCrude[, -1], 3)

dfForestDevCrude <- dfForestDevCrude %>%
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

dfForestDevCrude <- rbind(rowNames, dfForestDevCrude)

dfForestDevCrude[, c("OR", "Lower", "Upper")] <- apply(dfForestDevCrude[, c("OR", "Lower", "Upper")], 2, as.numeric)

print(dfForestDevCrude)

# plot
library(forestplot)

forestDevLogCrude <- forestplot(
    labeltext = as.matrix(dfForestDevCrude[, c(1, 2, 6)]),
    mean = dfForestDevCrude$OR,
    lower = dfForestDevCrude$Lower,
    upper = dfForestDevCrude$Upper,
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
    title = "Crude model (GCS difference)",
)

print(forestDevLogCrude)

# //!SECTION
