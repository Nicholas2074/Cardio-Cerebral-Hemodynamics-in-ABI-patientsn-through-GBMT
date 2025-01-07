# //SECTION - tuning

# //ANCHOR - day1

trajDay3 <- trajImp[trajImp$interval <= 18, ]

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

# gbmtListDay3 <- list()

# gbmtListDay3 <- foreach(i = 1:10, .packages = "gbmt") %dopar% {
#     gbmt(
#         x.names = varsAvg,
#         unit = "icuid",
#         time = "interval",
#         d = paraGrid[i, 1],
#         ng = paraGrid[i, 2],
#         data = trajDay3,
#         scaling = 2,
#         maxit = 200
#     )
# }

# # stop
# stopCluster(cl)

# gbmtListDay3Info <- lapply(gbmtListDay3, function(mod) {
#     mod$ic
# })

# print(gbmtListDay3Info)

# # gbmtListDay3[[2]] # model 2 is the best

# print(paraGrid)

# # //ANCHOR - modeling

# gbmt22Day3 <- gbmt(
#     x.names = varsAvg,
#     unit = "icuid",
#     time = "interval",
#     d = 2,
#     ng = 2,
#     data = trajDay3,
#     scaling = 2,
#     maxit = 200
# )

gbmt22Day3

# # traj group
# trajGroupDay3 <- as.data.frame(unique(trajDay3$icuid))
# names(trajGroupDay3) <- "icuid"

# trajAssignDay3 <- gbmt22Day3$assign.list

# trajGroupDay3$group[trajGroupDay3$icuid %in% trajAssignDay3[[1]]] <- 1
# trajGroupDay3$group[trajGroupDay3$icuid %in% trajAssignDay3[[2]]] <- 2
# # trajGroupDay3$group[trajGroupDay3$icuid %in% trajAssignDay3[[3]]] <- 3
# # trajGroupDay3$group[trajGroupDay3$icuid %in% trajAssignDay3[[4]]] <- 4
# # trajGroupDay3$group[trajGroupDay3$icuid %in% trajAssignDay3[[5]]] <- 5
# # trajGroupDay3$group[trajGroupDay3$icuid %in% trajAssignDay3[[6]]] <- 6

# trajGroupDay3$group <- as.factor(trajGroupDay3$group)

# //!SECTION

# //SECTION - hospMortality

# //ANCHOR - outcome

trajMorDay3 <- merge(trajGroupDay3, mortality, by = "icuid", all = FALSE)

print(length(unique(trajMorDay3$icuid)))

# //ANCHOR - logcrude

logMorCrudeDay3 <- glm(hospMortality ~ group, data = trajMorDay3, family = binomial)

summary(logMorCrudeDay3)

pMorCrudeDay3 <- coef(summary(logMorCrudeDay3))[, "Pr(>|z|)"]
pMorCrudeDay3

orMorCrudeDay3 <- exp(coef(logMorCrudeDay3))
orMorCrudeDay3

ciMorCrudeDay3 <- exp(confint(logMorCrudeDay3))
ciMorCrudeDay3

# //ANCHOR - logadjusted

names(dfCovMor)

dfTrajCovMorDay3 <- merge(trajGroupDay3, dfCovMor[, -3], by = "icuid", all = FALSE)

logMorAdjustedDay3 <- glm(
    hospMortality ~
        group +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfTrajCovMorDay3
)

# summary
summary(logMorAdjustedDay3)

pMorAdjustedDay3 <- coef(summary(logMorAdjustedDay3))[, "Pr(>|z|)"]
pMorAdjustedDay3

orMorAdjustedDay3 <- exp(coef(logMorAdjustedDay3))
orMorAdjustedDay3

ciMorAdjustedDay3 <- exp(confint(logMorAdjustedDay3))
ciMorAdjustedDay3

# //ANCHOR - result

library(tidyverse)

dfMorAdjustedDay3 <- data.frame(
    "Variable" = names(pMorAdjustedDay3),
    "P value" = pMorAdjustedDay3,
    "OR" = orMorAdjustedDay3,
    "Lower" = ciMorAdjustedDay3[, 1],
    "Upper" = ciMorAdjustedDay3[, 2],
    row.names = NULL
)

dfMorAdjustedDay3 <- dfMorAdjustedDay3[-1, ]

dfMorAdjustedDay3[, -1] <- round(dfMorAdjustedDay3[, -1], 3)

dfMorAdjustedDay3 <- dfMorAdjustedDay3 %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

dfMorAdjustedDay3 <- dfMorAdjustedDay3[, c("Variable", "P.value", "ORCI")]

print(dfMorAdjustedDay3)

# //!SECTION