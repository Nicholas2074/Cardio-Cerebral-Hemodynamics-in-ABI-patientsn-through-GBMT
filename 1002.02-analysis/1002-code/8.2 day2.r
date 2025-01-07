# //SECTION - tuning

# //ANCHOR - day1

trajDay2 <- trajImp[trajImp$interval <= 12, ]

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

# gbmtListDay2 <- list()

# gbmtListDay2 <- foreach(i = 1:10, .packages = "gbmt") %dopar% {
#     gbmt(
#         x.names = varsAvg,
#         unit = "icuid",
#         time = "interval",
#         d = paraGrid[i, 1],
#         ng = paraGrid[i, 2],
#         data = trajDay2,
#         scaling = 2,
#         maxit = 200
#     )
# }

# # stop
# stopCluster(cl)

# gbmtListDay2Info <- lapply(gbmtListDay2, function(mod) {
#     mod$ic
# })

# print(gbmtListDay2Info)

# # gbmtListDay2[[2]] # model 2 is the best

# print(paraGrid)

# # //ANCHOR - modeling

# gbmt22Day2 <- gbmt(
#     x.names = varsAvg,
#     unit = "icuid",
#     time = "interval",
#     d = 2,
#     ng = 2,
#     data = trajDay2,
#     scaling = 2,
#     maxit = 200
# )

gbmt22Day2

# # traj group
# trajGroupDay2 <- as.data.frame(unique(trajDay2$icuid))
# names(trajGroupDay2) <- "icuid"

# trajAssignDay2 <- gbmt22Day2$assign.list

# trajGroupDay2$group[trajGroupDay2$icuid %in% trajAssignDay2[[1]]] <- 1
# trajGroupDay2$group[trajGroupDay2$icuid %in% trajAssignDay2[[2]]] <- 2
# # trajGroupDay2$group[trajGroupDay2$icuid %in% trajAssignDay2[[3]]] <- 3
# # trajGroupDay2$group[trajGroupDay2$icuid %in% trajAssignDay2[[4]]] <- 4
# # trajGroupDay2$group[trajGroupDay2$icuid %in% trajAssignDay2[[5]]] <- 5
# # trajGroupDay2$group[trajGroupDay2$icuid %in% trajAssignDay2[[6]]] <- 6

# trajGroupDay2$group <- as.factor(trajGroupDay2$group)

# //!SECTION

# //SECTION - hospMortality

# //ANCHOR - outcome

trajMorDay2 <- merge(trajGroupDay2, mortality, by = "icuid", all = FALSE)

print(length(unique(trajMorDay2$icuid)))

# //ANCHOR - logcrude

logMorCrudeDay2 <- glm(hospMortality ~ group, data = trajMorDay2, family = binomial)

summary(logMorCrudeDay2)

pMorCrudeDay2 <- coef(summary(logMorCrudeDay2))[, "Pr(>|z|)"]
pMorCrudeDay2

orMorCrudeDay2 <- exp(coef(logMorCrudeDay2))
orMorCrudeDay2

ciMorCrudeDay2 <- exp(confint(logMorCrudeDay2))
ciMorCrudeDay2

# //ANCHOR - logadjusted

names(dfCovMor)

dfTrajCovMorDay2 <- merge(trajGroupDay2, dfCovMor[, -3], by = "icuid", all = FALSE)

logMorAdjustedDay2 <- glm(
    hospMortality ~
        group +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfTrajCovMorDay2
)

# summary
summary(logMorAdjustedDay2)

pMorAdjustedDay2 <- coef(summary(logMorAdjustedDay2))[, "Pr(>|z|)"]
pMorAdjustedDay2

orMorAdjustedDay2 <- exp(coef(logMorAdjustedDay2))
orMorAdjustedDay2

ciMorAdjustedDay2 <- exp(confint(logMorAdjustedDay2))
ciMorAdjustedDay2

# //ANCHOR - result

library(tidyverse)

dfMorAdjustedDay2 <- data.frame(
    "Variable" = names(pMorAdjustedDay2),
    "P value" = pMorAdjustedDay2,
    "OR" = orMorAdjustedDay2,
    "Lower" = ciMorAdjustedDay2[, 1],
    "Upper" = ciMorAdjustedDay2[, 2],
    row.names = NULL
)

dfMorAdjustedDay2 <- dfMorAdjustedDay2[-1, ]

dfMorAdjustedDay2[, -1] <- round(dfMorAdjustedDay2[, -1], 3)

dfMorAdjustedDay2 <- dfMorAdjustedDay2 %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

dfMorAdjustedDay2 <- dfMorAdjustedDay2[, c("Variable", "P.value", "ORCI")]

print(dfMorAdjustedDay2)

# //!SECTION