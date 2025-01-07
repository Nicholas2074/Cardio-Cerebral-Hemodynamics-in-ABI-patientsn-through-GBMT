# # //SECTION - tuning

# //ANCHOR - icp

library(tidyverse)

# icp
trajICP <- trajImp[, c("icuid", "interval", "avgicp")]

# convert the long format to wide format
trajICPW <- trajICP %>%
    pivot_wider(names_from = interval, values_from = avgicp)

# assign id to each patient
trajICPW <- trajICPW %>%
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
trajICPM <- as.matrix(merge(trajICPW, trajTime, by = "id"))

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

# solICP3 <- list()

# solICP3 <- foreach(i = 1:64, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajICPM[, 3:32],
#         A = trajICPM[, 33:62],
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
# bicICP3 <- list()

# for (i in 1:64) {
#     bicICP3[[i]] <- trajeRBIC(solICP3[[i]])
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

# solICP4 <- list()

# solICP4 <- foreach(i = 1:256, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajICPM[, 3:32],
#         A = trajICPM[, 33:62],
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
# bicICP4 <- list()

# for (i in 1:256) {
#     bicICP4[[i]] <- trajeRBIC(solICP4[[i]])
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

# solICP5 <- list()

# solICP5 <- foreach(i = 1:1024, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajICPM[, 3:32],
#         A = trajICPM[, 33:62],
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
# bicICP5 <- list()

# for (i in 1:1024) {
#     bicICP5[[i]] <- trajeRBIC(solICP5[[i]])
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

# solICP6 <- list()

# solICP6 <- foreach(i = 1:4096, .packages = "trajeR") %dopar% {
#     sol <- trajeR(
#         Y = trajICPM[, 3:32],
#         A = trajICPM[, 33:62],
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
# bicICP6 <- list()

# for (i in 1:4096) {
#     bicICP6[[i]] <- trajeRBIC(solICP6[[i]])
# }

# # //!SECTION

# //SECTION - modeling

# # //ANCHOR - selection

# bicMin3ICP <- trajeRBIC(solICP3[[which(unlist(bicICP3) == min(unlist(bicICP3)))]])
# print(bicMin3ICP)

# bicMin4ICP <- trajeRBIC(solICP4[[which(unlist(bicICP4) == min(unlist(bicICP4)))]])
# print(bicMin4ICP)

# bicMin5ICP <- trajeRBIC(solICP5[[which(unlist(bicICP5) == min(unlist(bicICP5)))]])
# print(bicMin5ICP)

# bicMin6ICP <- trajeRBIC(solICP6[[which(unlist(bicICP6) == min(unlist(bicICP6)))]])
# print(bicMin6ICP)

# bicMinFianlICP <- min(bicMin3ICP, bicMin4ICP, bicMin5ICP, bicMin6ICP)
# print(bicMinFianlICP)

# trajICP5 <- solICP5[[which(unlist(bicICP5) == min(unlist(bicICP5)))]]
# trajICP6 <- solICP6[[which(unlist(bicICP6) == min(unlist(bicICP6)))]]

# save(trajICP5, file = "trajICP5.RData")

# //ANCHOR - group

load("trajICP5.RData")

library(trajeR)

trajICP5

print(
    propAssign(
        trajICP5,
        Y = trajICPM[, 3:32],
        A = trajICPM[, 33:62]
    )
)

print(
    adequacy(
        trajICP5,
        Y = trajICPM[, 3:32],
        A = trajICPM[, 33:62]
    )
)

groupMatICP <- as.data.frame(GroupProb(
    trajICP5,
    Y = trajICPM[, 3:32],
    A = trajICPM[, 33:62]
))

groupMatICP$group <- max.col(groupMatICP[, 1:5])

trajGroupICP <- cbind(trajICPW[, c("id", "icuid")], groupMatICP[, c("group")])
names(trajGroupICP)[3] <- "group"

trajGroupICP$group <- as.factor(trajGroupICP$group)

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
# col6 <- "#444444"
# col6_1 <- paste0("#cccccc", trans)
cols15G <- c(col1_1, col2_1, col3_1, col4_1, col5_1)
cols25G <- c(col1, col2, col3, col4, col5)
vcol5G <- c(cols15G, cols25G)

# plot trajectory
library(trajeR)

plotrajeR(
    trajICP5,
    Y = trajICPM[, 3:32],
    A = trajICPM[, 33:62],
    col = vcol5G,
    xlab = "Hours after ICU admission",
    ylab = "ICP"
)

# //ANCHOR - legend

# color of legend
colorMapping <- c(
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
    legend = c("Group 5", "Group 4", "Group 3", "Group 2", "Group 1"),
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

trajMorICP <- merge(trajGroupICP, mortality, by = "icuid", all = FALSE)

print(length(unique(trajMorICP$icuid)))

# //ANCHOR - logcrude

logMorCrudeICP <- glm(hospMortality ~ group, data = trajMorICP, family = binomial)

summary(logMorCrudeICP)

pMorCrudeICP <- coef(summary(logMorCrudeICP))[, "Pr(>|z|)"]
pMorCrudeICP

orMorCrudeICP <- exp(coef(logMorCrudeICP))
orMorCrudeICP

ciMorCrudeICP <- exp(confint(logMorCrudeICP))
ciMorCrudeICP

# //ANCHOR - logadjusted

names(dfCovMor)

dfTrajCovMorICP <- merge(trajGroupICP, dfCovMor[, -6], by = "icuid", all = FALSE)

logMorAdjustedICP <- glm(
    hospMortality ~
        group +
        age +
        gender +
        bmi +
        # mild_liver_disease +
        resprate_avg +
        sodium,
    family = binomial,
    data = dfTrajCovMorICP
)

# summary
summary(logMorAdjustedICP)

pMorAdjustedICP <- coef(summary(logMorAdjustedICP))[, "Pr(>|z|)"]
pMorAdjustedICP

orMorAdjustedICP <- exp(coef(logMorAdjustedICP))
orMorAdjustedICP

ciMorAdjustedICP <- exp(confint(logMorAdjustedICP))
ciMorAdjustedICP

# //ANCHOR - result

library(tidyverse)

dfMorAdjustedICP <- data.frame(
    "Variable" = names(pMorAdjustedICP),
    "P value" = pMorAdjustedICP,
    "OR" = orMorAdjustedICP,
    "Lower" = ciMorAdjustedICP[, 1],
    "Upper" = ciMorAdjustedICP[, 2],
    row.names = NULL
)

dfMorAdjustedICP <- dfMorAdjustedICP[-1, ]

dfMorAdjustedICP[, -1] <- round(dfMorAdjustedICP[, -1], 3)

dfMorAdjustedICP <- dfMorAdjustedICP %>%
    mutate("ORCI" = paste(OR, "(", Lower, ",", Upper, ")"), )

print(dfMorAdjustedICP[, c(1, 2, 6)])

# //!SECTION
