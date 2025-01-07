# # # //SECTION - tuning

# # //ANCHOR - rpp

# library(tidyverse)

# # rpp
# trajRPP <- trajImp[, c("icuid", "interval", "avgrpp")]

# trajRPP$avgrpp <- scale(trajRPP$avgrpp)

# # convert the long format to wide format
# trajRPPW <- trajRPP %>%
#     pivot_wider(names_from = interval, values_from = avgrpp)

# # assign id to each patient
# trajRPPW <- trajRPPW %>%
#     mutate(id = row_number())

# # create an empty data frame
# trajTime <- data.frame(id = 1:370)

# # gene 30 columns
# # with time increasing by a step of 1
# for (i in seq(0, 29, by = 1)) {
#     col_name <- as.character(i)
#     trajTime[col_name] <- rep(i, 370)
# }

# # combine
# trajRPPM <- as.matrix(merge(trajRPPW, trajTime, by = "id"))

# # //ANCHOR - degre3

# degre3 <- expand.grid(0:3, 0:3, 0:3)
# dim(degre3)

# library(trajeR)

# library(doParallel)

# # clear env
# # env <- foreach:::.foreachGlobals
# # rm(list = ls(name = env), pos = env)

# # cores
# cores <- detectCores()
# cl <- makeCluster(cores - 1)
# registerDoParallel(cl)

# solRPP3 <- list()

# solRPP3 <- foreach(i = 1:64, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajRPPM[, 3:32],
#         A = trajRPPM[, 33:62],
#         degre = c(
#             degre3[i, 1],
#             degre3[i, 2],
#             degre3[i, 3]
#             ),
#         Model = "CNORM",
#         Method = "EM",
#         ssigma = FALSE,
#         hessian = TRUE,
#         itermax = 100,
#         ProbIRLS = TRUE
#     )
# }

# # stop parallel computing
# stopImplicitCluster()

# # bic value
# bicRPP3 <- list()

# for (i in 1:64) {
#     bicRPP3[[i]] <- trajeRBIC(solRPP3[[i]])
# }

# # //ANCHOR - degre4

# degre4 <- expand.grid(0:3, 0:3, 0:3, 0:3)
# dim(degre4)

# library(trajeR)

# library(doParallel)

# # clear env
# # env <- foreach:::.foreachGlobals
# # rm(list = ls(name = env), pos = env)

# # cores
# cores <- detectCores()
# cl <- makeCluster(cores - 1)
# registerDoParallel(cl)

# solRPP4 <- list()

# solRPP4 <- foreach(i = 1:256, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajRPPM[, 3:32],
#         A = trajRPPM[, 33:62],
#         degre = c(
#             degre4[i, 1],
#             degre4[i, 2],
#             degre4[i, 3],
#             degre4[i, 4]
#             ),
#         Model = "CNORM",
#         Method = "EM",
#         ssigma = FALSE,
#         hessian = TRUE,
#         itermax = 100,
#         ProbIRLS = TRUE
#     )
# }

# # stop parallel computing
# stopImplicitCluster()

# # bic value
# bicRPP4 <- list()

# for (i in 1:256) {
#     bicRPP4[[i]] <- trajeRBIC(solRPP4[[i]])
# }

# # //ANCHOR - degre5

# degre5 <- expand.grid(0:3, 0:3, 0:3, 0:3, 0:3)
# dim(degre5)

# library(trajeR)

# library(doParallel)

# # clear env
# # env <- foreach:::.foreachGlobals
# # rm(list = ls(name = env), pos = env)

# # cores
# cores <- detectCores()
# cl <- makeCluster(cores - 1)
# registerDoParallel(cl)

# solRPP5 <- list()

# solRPP5 <- foreach(i = 1:1024, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajRPPM[, 3:32],
#         A = trajRPPM[, 33:62],
#         degre = c(
#             degre5[i, 1],
#             degre5[i, 2],
#             degre5[i, 3],
#             degre5[i, 4],
#             degre5[i, 5]
#             ),
#         Model = "CNORM",
#         Method = "EM",
#         ssigma = FALSE,
#         hessian = TRUE,
#         itermax = 100,
#         ProbIRLS = TRUE
#     )
# }

# # stop parallel computing
# stopImplicitCluster()

# # bic value
# bicRPP5 <- list()

# for (i in 1:1024) {
#     bicRPP5[[i]] <- trajeRBIC(solRPP5[[i]])
# }

# # //ANCHOR - degre6

# degre6 <- expand.grid(0:3, 0:3, 0:3, 0:3, 0:3, 0:3)
# dim(degre6)

# library(trajeR)

# library(doParallel)

# # clear env
# # env <- foreach:::.foreachGlobals
# # rm(list = ls(name = env), pos = env)

# # cores
# cores <- detectCores()
# cl <- makeCluster(cores - 1)
# registerDoParallel(cl)

# solRPP6 <- list()

# solRPP6 <- foreach(i = 1:4096, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajRPPM[, 3:32],
#         A = trajRPPM[, 33:62],
#         degre = c(
#             degre6[i, 1],
#             degre6[i, 2],
#             degre6[i, 3],
#             degre6[i, 4],
#             degre6[i, 5],
#             degre6[i, 6]
#             ),
#         Model = "CNORM",
#         Method = "EM",
#         ssigma = FALSE,
#         hessian = TRUE,
#         itermax = 100,
#         ProbIRLS = TRUE
#     )
# }

# # stop parallel computing
# stopImplicitCluster()

# # bic value
# bicRPP6 <- list()

# for (i in 1:4096) {
#     bicRPP6[[i]] <- trajeRBIC(solRPP6[[i]])
# }

# # //!SECTION

# //SECTION - modeling

# # //ANCHOR - selection

# bicMin3RPP <- trajeRBIC(solRPP3[[which(unlist(bicRPP3) == min(unlist(bicRPP3)))]])
# print(bicMin3RPP)

# bicMin4RPP <- trajeRBIC(solRPP4[[which(unlist(bicRPP4) == min(unlist(bicRPP4)))]])
# print(bicMin4RPP)

# bicMin5RPP <- trajeRBIC(solRPP5[[which(unlist(bicRPP5) == min(unlist(bicRPP5)))]])
# print(bicMin5RPP)

# bicMin6RPP <- trajeRBIC(solRPP6[[which(unlist(bicRPP6) == min(unlist(bicRPP6)))]])
# print(bicMin6RPP)

# bicMinFianlRPP <- min(bicMin2RPP, bicMin3RPP, bicMin4RPP, bicMin5RPP, bicMin6RPP)
# print(bicMinFianlRPP)

# trajRPP5 <- solRPP5[[which(unlist(bicRPP5) == min(unlist(bicRPP5)))]]
# trajRPP6 <- solRPP6[[which(unlist(bicRPP6) == min(unlist(bicRPP6)))]]

# save(trajRPP6, file = "trajRPP6.RData")

# //ANCHOR - group

load("trajRPP6.RData")

library(trajeR)

trajRPP6

print(
    propAssign(
        trajRPP6,
        Y = trajRPPM[, 3:32],
        A = trajRPPM[, 33:62]
    )
)

print(
    adequacy(
        trajRPP6,
        Y = trajRPPM[, 3:32],
        A = trajRPPM[, 33:62]
    )
)

groupMatRPP <- as.data.frame(GroupProb(
    trajRPP6,
    Y = trajRPPM[, 3:32],
    A = trajRPPM[, 33:62]
))

groupMatRPP$group <- max.col(groupMatRPP[, 1:5])

trajGroupRPP <- cbind(trajRPPW[, c("id", "icuid")], groupMatRPP[, c("group")])
names(trajGroupRPP)[3] <- "group"

trajGroupRPP$group <- as.factor(trajGroupRPP$group)

# //ANCHOR - trajplot

# color of traj
trans <- "90"
col1 <- "#034569"
col1_1 <- paste0("#64AAD0", trans)
col2 <- "#750062"
col2_1 <- paste0("#D962C7", trans)
col3 <- "#A68900"
col3_1 <- paste0("#FFE773", trans)
col4 <- "#0fa408"
col4_1 <- paste0("#b5f2b5", trans)
col5 <- "#fb8502"
col5_1 <- paste0("#fbbf8f", trans)
col6 <- "#444444"
col6_1 <- paste0("#cccccc", trans)
cols16G <- c(col1_1, col2_1, col3_1, col4_1, col5_1, col6_1)
cols26G <- c(col1, col2, col3, col4, col5, col6)
vcol6G <- c(cols16G, cols26G)

# plot trajectory
library(trajeR)

plotrajeR(
    trajRPP6,
    Y = trajRPPM[, 3:32],
    A = trajRPPM[, 33:62],
    col = vcol6G,
    xlab = "Hours after ICU admission",
    ylab = "RPP"
)

# //ANCHOR - legend

# color of legend
colorMapping <- c(
    "Group 6" = "#444444",
    "Group 5" = "#fb8502",
    "Group 4" = "#0fa408",
    "Group 3" = "#A68900",
    "Group 2" = "#750062",
    "Group 1" = "#034569"
)

plot(1, type = "n")

# add legend
legend(
    "center",
    legend = c("Group 6", "Group 5", "Group 4", "Group 3", "Group 2", "Group 1"),
    col = colorMapping,
    lty = 1,
    bty = 1,
    lwd = 2,
    cex = 0.8,
    text.col = "black",
    ncol = 3
)

# //!SECTION

# //SECTION - hospMortality

# //ANCHOR - outcome

trajMorRPP <- merge(trajGroupRPP, mortality, by = "icuid", all = FALSE)

print(length(unique(trajMorRPP$icuid)))

# //ANCHOR - logcrude

logMorCrudeRPP <- glm(hospMortality ~ group, data = trajMorRPP, family = binomial)

summary(logMorCrudeRPP)

pMorCrudeRPP <- coef(summary(logMorCrudeRPP))[, "Pr(>|z|)"]
pMorCrudeRPP

orMorCrudeRPP <- exp(coef(logMorCrudeRPP))
orMorCrudeRPP

ciMorCrudeRPP <- exp(confint(logMorCrudeRPP))
ciMorCrudeRPP

# //ANCHOR - logadjusted

names(dfCovMor)

dfTrajCovMorRPP <- merge(trajGroupRPP, dfCovMor[, -6], by = "icuid", all = FALSE)

logMorAdjustedRPP <- glm(
    hospMortality ~
        group +
        age +
        gender +
        bmi +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfTrajCovMorRPP
)

# summary
summary(logMorAdjustedRPP)

pMorAdjustedRPP <- coef(summary(logMorAdjustedRPP))[, "Pr(>|z|)"]
pMorAdjustedRPP

orMorAdjustedRPP <- exp(coef(logMorAdjustedRPP))
orMorAdjustedRPP

ciMorAdjustedRPP <- exp(confint(logMorAdjustedRPP))
ciMorAdjustedRPP

# //ANCHOR - result

library(tidyverse)

dfMorAdjustedRPP <- data.frame(
    "Variable" = names(pMorAdjustedRPP),
    "P value" = pMorAdjustedRPP,
    "OR" = orMorAdjustedRPP,
    "Lower" = ciMorAdjustedRPP[, 1],
    "Upper" = ciMorAdjustedRPP[, 2],
    row.names = NULL
)

dfMorAdjustedRPP <- dfMorAdjustedRPP[-1, ]

dfMorAdjustedRPP[, -1] <- round(dfMorAdjustedRPP[, -1], 3)

dfMorAdjustedRPP <- dfMorAdjustedRPP %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

print(dfMorAdjustedRPP[, c(1, 2, 6)])

# //!SECTION
