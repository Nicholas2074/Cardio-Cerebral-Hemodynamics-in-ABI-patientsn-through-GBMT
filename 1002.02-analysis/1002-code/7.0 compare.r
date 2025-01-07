# //SECTION - traj predictors

# //ANCHOR - comparegroups

dfPredTraj <- dfCTTraj

library(compareGroups)

tablePredTraj <- descrTable(group ~ . - icuid,
    data = dfPredTraj,
    method = NA,
    show.all = TRUE
)

export2word(tablePredTraj, file = "tablePredTraj.docx")

# //ANCHOR - pairwise

bonfAvgICPPred <- pairwise.t.test(dfPredTraj$avgicp, dfPredTraj$group, p.adj = "bonf", data = dfPredTraj)
print(bonfAvgICPPred)

bonfCVCPPPred <- pairwise.t.test(dfPredTraj$cvcpp, dfPredTraj$group, p.adj = "bonf", data = dfPredTraj)
print(bonfCVCPPPred)

bonfCVICPPred <- pairwise.t.test(dfPredTraj$cvicp, dfPredTraj$group, p.adj = "bonf", data = dfPredTraj)
print(bonfCVICPPred)

bonfCVRPPPred <- pairwise.t.test(dfPredTraj$cvrpp, dfPredTraj$group, p.adj = "bonf", data = dfPredTraj)
print(bonfCVRPPPred)

bonfPaco2Pred <- pairwise.t.test(dfPredTraj$paco2, dfPredTraj$group, p.adj = "bonf", data = dfPredTraj)
print(bonfPaco2Pred)

bonfSodiumPred <- pairwise.t.test(dfPredTraj$sodium, dfPredTraj$group, p.adj = "bonf", data = dfPredTraj)
print(bonfSodiumPred)

# //!SECTION

# //SECTION - 5day mean indicators

library(tidyverse)

dfDay5 <- icpBpHr2[, c("icuid", "icp", "cpp", "rpp")] %>%
    group_by(icuid) %>%
    summarize(
        avgicp = round(mean(icp, na.rm = TRUE), 2),
        avgcpp = round(mean(cpp, na.rm = TRUE), 2),
        avgrpp = round(mean(rpp, na.rm = TRUE), 2),
        cvicp = round((sd(icp, na.rm = TRUE) / mean(icp, na.rm = TRUE)), 2),
        cvcpp = round((sd(cpp, na.rm = TRUE) / mean(cpp, na.rm = TRUE)), 2),
        cvrpp = round((sd(rpp, na.rm = TRUE) / mean(rpp, na.rm = TRUE)), 2),
        .groups = "drop"
    )

dfDay5 <- dfDay5[dfDay5$icuid %in% trajImp$icuid, ]

dfDay5Traj <- merge(trajGroup, dfDay5, by = "icuid", all.x = TRUE)

# //ANCHOR - comparegroups

library(compareGroups)

tableDay5Traj <- descrTable(group ~ . - icuid,
    data = dfDay5Traj,
    method = NA,
    show.all = TRUE
)

export2word(tableDay5Traj, file = "tableDay5Traj.docx")

# //ANCHOR - pairwise

bonfAvgICPDay5 <- pairwise.t.test(dfDay5Traj$avgicp, dfDay5Traj$group, p.adj = "bonf", data = dfDay5Traj)
print(bonfAvgICPDay5)

bonfAvgCPPDay5 <- pairwise.t.test(dfDay5Traj$avgcpp, dfDay5Traj$group, p.adj = "bonf", data = dfDay5Traj)
print(bonfAvgCPPDay5)

bonfAvgRPPDay5 <- pairwise.t.test(dfDay5Traj$avgrpp, dfDay5Traj$group, p.adj = "bonf", data = dfDay5Traj)
print(bonfAvgRPPDay5)

bonfCVICPDay5 <- pairwise.t.test(dfDay5Traj$cvicp, dfDay5Traj$group, p.adj = "bonf", data = dfDay5Traj)
print(bonfCVICPDay5)

bonfCVCPPDay5 <- pairwise.t.test(dfDay5Traj$cvcpp, dfDay5Traj$group, p.adj = "bonf", data = dfDay5Traj)
print(bonfCVCPPDay5)

bonfCVRPPDay5 <- pairwise.t.test(dfDay5Traj$cvrpp, dfDay5Traj$group, p.adj = "bonf", data = dfDay5Traj)
print(bonfCVRPPDay5)

# //!SECTION