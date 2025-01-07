# //SECTION - boruta

library(mlr3verse)

library(tidyverse)

# //ANCHOR - preprocess

dfTrajDay1 <- icpBpHr2[icpBpHr2$interval <= 288, c("icuid", "icp", "cpp", "rpp")] %>%
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

dfTrajDay1 <- dfTrajDay1[dfTrajDay1$icuid %in% trajImp$icuid, ]

dfTraj <- merge(varsImp, dfTrajDay1, by = "icuid", all = FALSE)

library(missForest)

set.seed(0)

dfTrajMf <- missForest(dfTraj)

dfTraj <- dfTrajMf$ximp

library(mlr3verse)

# delete icuid
dfTrajDel <- dfTraj[, -1]

dfTrajDel$group <- ifelse(dfTrajDel$group == 4, 1, 0)

# task definition
taskTraj <- as_task_classif(dfTrajDel, target = "group", positive = "1")
names(dfTrajDel)

# pipline building
po1Traj <-
    po(
        "removeconstants" # rm constant vars
    ) %>>%
    po("filter", # rm highly correlated vars
        filter = flt("find_correlation"), filter.cutoff = 0.4
    ) %>>%
    po("encode",
        method = "one-hot", # one-hot encoding
        affect_columns = selector_type("factor")
    ) %>>%
    po("scale",
        scale = FALSE, # scale
        affect_columns = selector_type("numeric")
    )

# pipline application
taskTrajPo1 <- po1Traj$train(taskTraj)[[1]]
names(taskTrajPo1$data())

# //ANCHOR - boruta

library(Boruta)

set.seed(0)

trajPo1Boruta <- Boruta(group ~ .,
    data = taskTrajPo1$data(),
    maxRuns = 2000
)
# trajPo1Boruta

# trajPo1Boruta$finalDecision

trajNamesConf <- names(trajPo1Boruta$finalDecision[trajPo1Boruta$finalDecision == "Confirmed"])
print(trajNamesConf)

trajNamesTent <- names(trajPo1Boruta$finalDecision[trajPo1Boruta$finalDecision == "Tentative"])
print(trajNamesTent)

trajNames <- c(trajNamesConf, trajNamesTent)
print(trajNames)

# Boruta::plotImpHistory(trajPo1Boruta)

# plot(trajPo1Boruta, xlab = "Attributes", ylab = "Importance:Z-Score", las = 2)

# //ANCHOR - reshape

# install.packages("devtools")
# devtools::install_github("Tong-Chen/ImageGP")

library(ImageGP)

# -------------------------------- plot start -------------------------------- #
boruta.variable.imp <- boruta.imp(trajPo1Boruta)

sp_boxplot(boruta.variable.imp, melted=T, xvariable = "Variable", yvariable = "Importance",
           legend_variable = "finalDecision", legend_variable_order = c("shadowMax", "shadowMean", "shadowMin", "Confirmed"),
           xtics_angle = 90)
# --------------------------------- plot end --------------------------------- #

# //!SECTION

# //SECTION - shap

# //ANCHOR - preprocess

# task definition
taskTrajSub <- taskTrajPo1$select(trajNames)

# pipeline building
po2Traj <-
    po(
        "classbalancing",
        reference = "major", adjust = "minor", shuffle = FALSE, ratio = 1
    )

# pipeline application
set.seed(0)

taskTrajSubPo2 <- po2Traj$train(list(taskTrajSub))[[1]]
names(taskTrajSubPo2$data())

# //ANCHOR - afs

# split to train and external set
splitTraj <- partition(taskTrajSubPo2, ratio = 0.8)

# create auto fselector
afsTraj <- auto_fselector(
    fselector = fs("rfe"),
    learner = lrn("classif.ranger", importance = "impurity", predict_type = "prob"),
    resampling = rsmp("holdout"),
    measure = msr("classif.ce"),
    term_evals = 20
)

# log output
lgr::get_logger("mlr3")$set_threshold("warn")
lgr::get_logger("bbotk")$set_threshold("warn")

# optimize feature subset and fit final model
afsTraj$train(taskTrajSubPo2, splitTraj$train)

# predict with final model
afsTraj$predict(taskTrajSubPo2, splitTraj$test)

# show result
print(afsTraj$fselect_result$importance)

rfTraj <- afsTraj$learner

# //ANCHOR - visualization

taskTrajSubAfs <- taskTrajSubPo2$select(afsTraj$fselect_result$feature[[1]])

dfShapTraj <- taskTrajSubAfs$data()

# shap
library(kernelshap)

shapKsTraj <- kernelshap(rfTraj, dfShapTraj[1:300, -1], dfShapTraj)

# viz
library(shapviz)

vizKsTraj <- shapviz(shapKsTraj, which_class = 1)

# -------------------------------- plot start -------------------------------- #
sv_importance(vizKsTraj, kind = "beeswarm")

# dfShapTraj[, ]
# sv_force(vizKsTraj, row_id = 1) # ture negative
# dfShapTraj[, ]
# sv_force(vizKsTraj, row_id = 9) # ture positive
# --------------------------------- plot end --------------------------------- #

# interaction
library(vivid)

viTraj <- vivi(data = dfShapTraj, fit = rfTraj, response = "group")

# -------------------------------- plot start -------------------------------- #
# # heatmap
# viviHeatmap(
#     viTraj,
#     intPal = rev(
#         colorspace::sequential_hcl(palette = "Sunset", n = 100)
#     ), # color of interaction
#     impPal = rev(
#         colorspace::sequential_hcl(palette = "RdPu", n = 100)
#     ) # color of vars importance
# )

# # network
# viviNetwork(
#     viTraj,
#     intPal = rev(
#         colorspace::sequential_hcl(palette = "Sunset", n = 100)
#     ), # color of interaction
#     impPal = rev(
#         colorspace::sequential_hcl(palette = "RdPu", n = 100)
#     ) # color of vars importance
# )
# --------------------------------- plot end --------------------------------- #

# //ANCHOR - covariate

# subset
dfCTTraj <- dfTraj[, c("icuid", "group", trajNames)]

# ---------------------------------------------------------------------------- #
#                               do not regroup!!!                              #
# ---------------------------------------------------------------------------- #

# //!SECTION