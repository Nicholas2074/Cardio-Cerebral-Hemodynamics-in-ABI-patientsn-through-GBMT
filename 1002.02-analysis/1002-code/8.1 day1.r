# //SECTION - tuning

# //ANCHOR - day1

trajDay1 <- trajImp[trajImp$interval <= 6, ]

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

# gbmtListDay1 <- list()

# gbmtListDay1 <- foreach(i = 1:10, .packages = "gbmt") %dopar% {
#     gbmt(
#         x.names = varsAvg,
#         unit = "icuid",
#         time = "interval",
#         d = paraGrid[i, 1],
#         ng = paraGrid[i, 2],
#         data = trajDay1,
#         scaling = 2,
#         maxit = 200
#     )
# }

# # stop
# stopCluster(cl)

# gbmtListDay1Info <- lapply(gbmtListDay1, function(mod) {
#     mod$ic
# })

# print(gbmtListDay1Info)

# # gbmtListDay1[[3]] # model 3 is the best

# print(paraGrid)

# # //ANCHOR - modeling

# gbmt23Day1 <- gbmt(
#     x.names = varsAvg,
#     unit = "icuid",
#     time = "interval",
#     d = 2,
#     ng = 3,
#     data = trajDay1,
#     scaling = 2,
#     maxit = 200
# )

gbmt23Day1
 
# # traj group
# trajGroupDay1 <- as.data.frame(unique(trajDay1$icuid))
# names(trajGroupDay1) <- "icuid"

# trajAssignDay1 <- gbmt23Day1$assign.list

# trajGroupDay1$group[trajGroupDay1$icuid %in% trajAssignDay1[[1]]] <- 1
# trajGroupDay1$group[trajGroupDay1$icuid %in% trajAssignDay1[[2]]] <- 2
# trajGroupDay1$group[trajGroupDay1$icuid %in% trajAssignDay1[[3]]] <- 3
# # trajGroupDay1$group[trajGroupDay1$icuid %in% trajAssignDay1[[4]]] <- 4
# # trajGroupDay1$group[trajGroupDay1$icuid %in% trajAssignDay1[[5]]] <- 5
# # trajGroupDay1$group[trajGroupDay1$icuid %in% trajAssignDay1[[6]]] <- 6

# trajGroupDay1$group <- as.factor(trajGroupDay1$group)

# //!SECTION

# //SECTION - hospMortality

# //ANCHOR - outcome

trajMorDay1 <- merge(trajGroupDay1, mortality, by = "icuid", all = FALSE)

print(length(unique(trajMorDay1$icuid)))

# //ANCHOR - logcrude

logMorCrudeDay1 <- glm(hospMortality ~ group, data = trajMorDay1, family = binomial)

summary(logMorCrudeDay1)

pMorCrudeDay1 <- coef(summary(logMorCrudeDay1))[, "Pr(>|z|)"]
pMorCrudeDay1

orMorCrudeDay1 <- exp(coef(logMorCrudeDay1))
orMorCrudeDay1

ciMorCrudeDay1 <- exp(confint(logMorCrudeDay1))
ciMorCrudeDay1

# //ANCHOR - logadjusted

names(dfCovMor)

dfTrajCovMorDay1 <- merge(trajGroupDay1, dfCovMor[, -3], by = "icuid", all = FALSE)

logMorAdjustedDay1 <- glm(
    hospMortality ~
        group +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfTrajCovMorDay1
)

# summary
summary(logMorAdjustedDay1)

pMorAdjustedDay1 <- coef(summary(logMorAdjustedDay1))[, "Pr(>|z|)"]
pMorAdjustedDay1

orMorAdjustedDay1 <- exp(coef(logMorAdjustedDay1))
orMorAdjustedDay1

ciMorAdjustedDay1 <- exp(confint(logMorAdjustedDay1))
ciMorAdjustedDay1

# //ANCHOR - result

library(tidyverse)

dfMorAdjustedDay1 <- data.frame(
    "Variable" = names(pMorAdjustedDay1),
    "P value" = pMorAdjustedDay1,
    "OR" = orMorAdjustedDay1,
    "Lower" = ciMorAdjustedDay1[, 1],
    "Upper" = ciMorAdjustedDay1[, 2],
    row.names = NULL
)

dfMorAdjustedDay1 <- dfMorAdjustedDay1[-1, ]

dfMorAdjustedDay1[, -1] <- round(dfMorAdjustedDay1[, -1], 3)

dfMorAdjustedDay1 <- dfMorAdjustedDay1 %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

dfMorAdjustedDay1 <- dfMorAdjustedDay1[, c("Variable", "P.value", "ORCI")]

print(dfMorAdjustedDay1)

# //!SECTION