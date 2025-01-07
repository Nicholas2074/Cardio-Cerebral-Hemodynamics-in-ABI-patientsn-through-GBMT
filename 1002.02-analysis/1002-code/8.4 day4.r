# //SECTION - tuning

# //ANCHOR - day1

trajDay4 <- trajImp[trajImp$interval <= 18, ]

# # //ANCHOR - grid search

# # parallel computing
# library(gbmt)

# library(doParallel)

# # clear env
# # env <- foreach:::.foreachGlobals
# # rm(list = ls(name = env), pos = env)

# # cores
# cores <- detectCores()
# cl <- makeCluster(cores)
# registerDoParallel(cl)

# gbmtListDay4 <- list()

# gbmtListDay4 <- foreach(i = 1:10, .packages = "gbmt") %dopar% {
#     gbmt(
#         x.names = varsAvg,
#         unit = "icuid",
#         time = "interval",
#         d = paraGrid[i, 1],
#         ng = paraGrid[i, 2],
#         data = trajDay4,
#         scaling = 2,
#         maxit = 200
#     )
# }

# # stop
# stopCluster(cl)

# gbmtListDay4Info <- lapply(gbmtListDay4, function(mod) {
#     mod$ic
# })

# print(gbmtListDay4Info)

# # gbmtListDay4[[2]] # model 2 is the best

# print(paraGrid)

# # //ANCHOR - modeling

# gbmt22Day4 <- gbmt(
#     x.names = varsAvg,
#     unit = "icuid",
#     time = "interval",
#     d = 2,
#     ng = 2,
#     data = trajDay4,
#     scaling = 2,
#     maxit = 200
# )

gbmt22Day4

# # traj group
# trajGroupDay4 <- as.data.frame(unique(trajDay4$icuid))
# names(trajGroupDay4) <- "icuid"

# trajAssignDay4 <- gbmt22Day4$assign.list

# trajGroupDay4$group[trajGroupDay4$icuid %in% trajAssignDay4[[1]]] <- 1
# trajGroupDay4$group[trajGroupDay4$icuid %in% trajAssignDay4[[2]]] <- 2
# # trajGroupDay4$group[trajGroupDay4$icuid %in% trajAssignDay4[[3]]] <- 3
# # trajGroupDay4$group[trajGroupDay4$icuid %in% trajAssignDay4[[4]]] <- 4
# # trajGroupDay4$group[trajGroupDay4$icuid %in% trajAssignDay4[[5]]] <- 5
# # trajGroupDay4$group[trajGroupDay4$icuid %in% trajAssignDay4[[6]]] <- 6

# trajGroupDay4$group <- as.factor(trajGroupDay4$group)

# //!SECTION

# //SECTION - hospMortality

# //ANCHOR - outcome

trajMorDay4 <- merge(trajGroupDay4, mortality, by = "icuid", all = FALSE)

print(length(unique(trajMorDay4$icuid)))

# //ANCHOR - logcrude

logMorCrudeDay4 <- glm(hospMortality ~ group, data = trajMorDay4, family = binomial)

summary(logMorCrudeDay4)

pMorCrudeDay4 <- coef(summary(logMorCrudeDay4))[, "Pr(>|z|)"]
pMorCrudeDay4

orMorCrudeDay4 <- exp(coef(logMorCrudeDay4))
orMorCrudeDay4

ciMorCrudeDay4 <- exp(confint(logMorCrudeDay4))
ciMorCrudeDay4

# //ANCHOR - logadjusted

names(dfCovMor)

dfTrajCovMorDay4 <- merge(trajGroupDay4, dfCovMor[, -3], by = "icuid", all = FALSE)

logMorAdjustedDay4 <- glm(
    hospMortality ~
        group +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfTrajCovMorDay4
)

# summary
summary(logMorAdjustedDay4)

pMorAdjustedDay4 <- coef(summary(logMorAdjustedDay4))[, "Pr(>|z|)"]
pMorAdjustedDay4

orMorAdjustedDay4 <- exp(coef(logMorAdjustedDay4))
orMorAdjustedDay4

ciMorAdjustedDay4 <- exp(confint(logMorAdjustedDay4))
ciMorAdjustedDay4

# //ANCHOR - result

library(tidyverse)

dfMorAdjustedDay4 <- data.frame(
    "Variable" = names(pMorAdjustedDay4),
    "P value" = pMorAdjustedDay4,
    "OR" = orMorAdjustedDay4,
    "Lower" = ciMorAdjustedDay4[, 1],
    "Upper" = ciMorAdjustedDay4[, 2],
    row.names = NULL
)

dfMorAdjustedDay4 <- dfMorAdjustedDay4[-1, ]

dfMorAdjustedDay4[, -1] <- round(dfMorAdjustedDay4[, -1], 3)

dfMorAdjustedDay4 <- dfMorAdjustedDay4 %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

dfMorAdjustedDay4 <- dfMorAdjustedDay4[, c("Variable", "P.value", "ORCI")]

print(dfMorAdjustedDay4)

# //!SECTION