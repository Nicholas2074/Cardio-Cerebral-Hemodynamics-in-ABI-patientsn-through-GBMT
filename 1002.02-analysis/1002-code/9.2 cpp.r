# # //SECTION - tuning

# //ANCHOR - cpp

library(tidyverse)

# cpp
trajCPP <- trajImp[, c("icuid", "interval", "avgcpp")]

# convert the long format to wide format
trajCPPW <- trajCPP %>%
    pivot_wider(names_from = interval, values_from = avgcpp)

# assign id to each patient
trajCPPW <- trajCPPW %>%
    mutate(id = row_number())

# create an empty data frame
trajTime <- data.frame(id = 1:370)

# gene 30 columns
# with time increasing by a step of 1
for (i in seq(0, 29, by = 1)) {
    col_name <- as.character(i)
    trajTime[col_name] <- rep(i, 370)
}

# combine
trajCPPM <- as.matrix(merge(trajCPPW, trajTime, by = "id"))

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

# solCPP3 <- list()

# solCPP3 <- foreach(i = 1:64, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajCPPM[, 3:32],
#         A = trajCPPM[, 33:62],
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
# bicCPP3 <- list()

# for (i in 1:64) {
#     bicCPP3[[i]] <- trajeRBIC(solCPP3[[i]])
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

# solCPP4 <- list()

# solCPP4 <- foreach(i = 1:256, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajCPPM[, 3:32],
#         A = trajCPPM[, 33:62],
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
# bicCPP4 <- list()

# for (i in 1:256) {
#     bicCPP4[[i]] <- trajeRBIC(solCPP4[[i]])
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

# solCPP5 <- list()

# solCPP5 <- foreach(i = 1:1024, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajCPPM[, 3:32],
#         A = trajCPPM[, 33:62],
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
# bicCPP5 <- list()

# for (i in 1:1024) {
#     bicCPP5[[i]] <- trajeRBIC(solCPP5[[i]])
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

# solCPP6 <- list()

# solCPP6 <- foreach(i = 1:4096, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajCPPM[, 3:32],
#         A = trajCPPM[, 33:62],
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
# bicCPP6 <- list()

# for (i in 1:4096) {
#     bicCPP6[[i]] <- trajeRBIC(solCPP6[[i]])
# }

# # //!SECTION

# //SECTION - modeling

# # //ANCHOR - selection

# bicMin3CPP <- trajeRBIC(solCPP3[[which(unlist(bicCPP3) == min(unlist(bicCPP3)))]])
# print(bicMin3CPP)

# bicMin4CPP <- trajeRBIC(solCPP4[[which(unlist(bicCPP4) == min(unlist(bicCPP4)))]])
# print(bicMin4CPP)

# bicMin5CPP <- trajeRBIC(solCPP5[[which(unlist(bicCPP5) == min(unlist(bicCPP5)))]])
# print(bicMin5CPP)

# bicMin6CPP <- trajeRBIC(solCPP6[[which(unlist(bicCPP6) == min(unlist(bicCPP6)))]])
# print(bicMin6CPP)

# bicMinFianlCPP <- min(bicMin3CPP, bicMin4CPP, bicMin5CPP, bicMin6CPP)
# print(bicMinFianlCPP)

# trajCPP4 <- solCPP4[[which(unlist(bicCPP4) == min(unlist(bicCPP4)))]]
# trajCPP5 <- solCPP5[[which(unlist(bicCPP5) == min(unlist(bicCPP5)))]]

# save(trajCPP4, file = "trajCPP4.RData")

# //ANCHOR - group

load("trajCPP4.RData")

library(trajeR)

trajCPP4

print(
    propAssign(
        trajCPP4,
        Y = trajCPPM[, 3:32],
        A = trajCPPM[, 33:62]
    )
)

print(
    adequacy(
        trajCPP4,
        Y = trajCPPM[, 3:32],
        A = trajCPPM[, 33:62]
    )
)

groupMatCPP <- as.data.frame(GroupProb(
    trajCPP4,
    Y = trajCPPM[, 3:32],
    A = trajCPPM[, 33:62]
))

groupMatCPP$group <- max.col(groupMatCPP[, 1:4])

trajGroupCPP <- cbind(trajCPPW[, c("id", "icuid")], groupMatCPP[, c("group")])
names(trajGroupCPP)[3] <- "group"

trajGroupCPP$group <- as.factor(trajGroupCPP$group)

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
# col5 <- "#fb8502"
# col5_1 <- paste0("#fbbf8f", trans)
# col6 <- "#444444"
# col6_1 <- paste0("#cccccc", trans)
cols14G <- c(col1_1, col2_1, col3_1, col4_1)
cols24G <- c(col1, col2, col3, col4)
vcol4G <- c(cols14G, cols24G)

# plot trajectory
library(trajeR)

plotrajeR(
    trajCPP4,
    Y = trajCPPM[, 3:32],
    A = trajCPPM[, 33:62],
    col = vcol4G,
    xlab = "Hours after ICU admission",
    ylab = "CPP"
)

# //ANCHOR - legend

# color of legend
colorMapping <- c(
    "Group 4" = "#0fa408",
    "Group 3" = "#A68900",
    "Group 2" = "#750062",
    "Group 1" = "#034569"
)

plot(1, type = "n")

# add legend
legend(
    "center",
    legend = c("Group 4", "Group 3", "Group 2", "Group 1"),
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

trajMorCPP <- merge(trajGroupCPP, mortality, by = "icuid", all = FALSE)

print(length(unique(trajMorCPP$icuid)))

# //ANCHOR - logcrude

logMorCrudeCPP <- glm(hospMortality ~ group, data = trajMorCPP, family = binomial)

summary(logMorCrudeCPP)

pMorCrudeCPP <- coef(summary(logMorCrudeCPP))[, "Pr(>|z|)"]
pMorCrudeCPP

orMorCrudeCPP <- exp(coef(logMorCrudeCPP))
orMorCrudeCPP

ciMorCrudeCPP <- exp(confint(logMorCrudeCPP))
ciMorCrudeCPP

# //ANCHOR - logadjusted

names(dfCovMor)

dfTrajCovMorCPP <- merge(trajGroupCPP, dfCovMor[, -6], by = "icuid", all = FALSE)

logMorAdjustedCPP <- glm(
    hospMortality ~
        group +
        age +
        gender +
        bmi +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfTrajCovMorCPP
)

# summary
summary(logMorAdjustedCPP)

pMorAdjustedCPP <- coef(summary(logMorAdjustedCPP))[, "Pr(>|z|)"]
pMorAdjustedCPP

orMorAdjustedCPP <- exp(coef(logMorAdjustedCPP))
orMorAdjustedCPP

ciMorAdjustedCPP <- exp(confint(logMorAdjustedCPP))
ciMorAdjustedCPP

# //ANCHOR - result

library(tidyverse)

dfMorAdjustedCPP <- data.frame(
    "Variable" = names(pMorAdjustedCPP),
    "P value" = pMorAdjustedCPP,
    "OR" = orMorAdjustedCPP,
    "Lower" = ciMorAdjustedCPP[, 1],
    "Upper" = ciMorAdjustedCPP[, 2],
    row.names = NULL
)

dfMorAdjustedCPP <- dfMorAdjustedCPP[-1, ]

dfMorAdjustedCPP[, -1] <- round(dfMorAdjustedCPP[, -1], 3)

dfMorAdjustedCPP <- dfMorAdjustedCPP %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

print(dfMorAdjustedCPP[, c(1, 2, 6)])

# //!SECTION
