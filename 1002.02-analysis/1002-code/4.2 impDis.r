# //SECTION - boruta

library(mlr3verse)

library(tidyverse)

# //ANCHOR - preprocess

dfDis <- merge(varsImp, gcs[, c(1, 3)], by = "icuid", all = FALSE)

# delete icuid
dfDisDel <- dfDis[, -1]

# regroup
dfDisDel$group <- ifelse(dfDisDel$group == 4, 1, 0)

# task definition
taskDis <- as_task_classif(dfDisDel, target = "disgcs", positive = "1")

# pipline building
po1Dis <-
    po(
        "removeconstants" # rm constant vars
    ) %>>%
    po("filter", # rm highly correlated vars
        filter = flt("find_correlation"), filter.cutoff = 0.7
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
taskDisPo1 <- po1Dis$train(taskDis)[[1]]
names(taskDisPo1$data())

# //ANCHOR - boruta

library(Boruta)

set.seed(0)

disPo1Boruta <- Boruta(disgcs ~ .,
    data = taskDisPo1$data(),
    maxRuns = 200
)
# disPo1Boruta

# disPo1Boruta$finalDecision

disNamesConf <- names(disPo1Boruta$finalDecision[disPo1Boruta$finalDecision == "Confirmed"])
print(disNamesConf)

disNamesTent <- names(disPo1Boruta$finalDecision[disPo1Boruta$finalDecision == "Tentative"])
print(disNamesTent)

disNames <- c(disNamesConf, disNamesTent)
print(disNames)

# Boruta::plotImpHistory(disPo1Boruta)

# plot(disPo1Boruta, xlab = "Attributes", ylab = "Importance:Z-Score", las = 2)

# //ANCHOR - reshape

# install.packages("devtools")
# devtools::install_github("Tong-Chen/ImageGP")

library(ImageGP)

# -------------------------------- plot start -------------------------------- #
boruta.variable.imp <- boruta.imp(disPo1Boruta)

sp_boxplot(boruta.variable.imp, melted=T, xvariable = "Variable", yvariable = "Importance",
           legend_variable = "finalDecision", legend_variable_order = c("shadowMax", "shadowMean", "shadowMin", "Confirmed"),
           xtics_angle = 90)
# --------------------------------- plot end --------------------------------- #

# //!SECTION

# //SECTION - shap

# //ANCHOR - preprocess

# task definition
taskDisSub <- taskDisPo1$select(disNames)

# pipeline building
po2Dis <-
    po(
        "classbalancing",
        reference = "major", adjust = "minor", shuffle = FALSE, ratio = 1
    )

# pipeline application
set.seed(0)

taskDisSubPo2 <- po2Dis$train(list(taskDisSub))[[1]]
names(taskDisSubPo2$data())

# //ANCHOR - afs

# split to train and external set
splitDis <- partition(taskDisSubPo2, ratio = 0.8)

# create auto fselector
afsDis <- auto_fselector(
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
afsDis$train(taskDisSubPo2, splitDis$train)

# predict with final model
afsDis$predict(taskDisSubPo2, splitDis$test)

# show result
print(afsDis$fselect_result$importance)

rfDis <- afsDis$learner

# //ANCHOR - visualization

taskDisSubAfs <- taskDisSubPo2$select(afsDis$fselect_result$feature[[1]])

dfShapDis <- taskDisSubAfs$data()

# shap
library(kernelshap)

shapKsDis <- kernelshap(rfDis, dfShapDis[1:300, -1], dfShapDis)

# viz
library(shapviz)

vizKsDis <- shapviz(shapKsDis, which_class = 1)

# -------------------------------- plot start -------------------------------- #
sv_importance(vizKsDis, kind = "beeswarm")

# dfShapDis[, ]
# sv_force(vizKsDis, row_id = 1) # ture negative
# dfShapDis[, ]
# sv_force(vizKsDis, row_id = 9) # ture positive
# --------------------------------- plot end --------------------------------- #

# interaction
library(vivid)

viDis <- vivi(data = dfShapDis, fit = rfDis, response = "disgcs")

# -------------------------------- plot start -------------------------------- #
# heatmap
viviHeatmap(
    viDis,
    intPal = rev(
        colorspace::sequential_hcl(palette = "Sunset", n = 100)
    ), # color of interaction
    impPal = rev(
        colorspace::sequential_hcl(palette = "RdPu", n = 100)
    ) # color of vars importance
)

# # network
# viviNetwork(
#     viDis,
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
dfCovDis <- dfDis[, c("icuid", "age", "gender", "bmi", disNamesConf)]

# regroup
dfCovDis$group <- ifelse(dfCovDis$group == 4, 1, 0)

# merge
dfCovDis <- merge(gcs[, c(1, 3)], dfCovDis, by = "icuid", all = FALSE)

# //!SECTION