# //SECTION - boruta

library(mlr3verse)

library(tidyverse)

# //ANCHOR - preprocess

dfDev <- merge(varsImp, gcs[, c(1, 4)], by = "icuid", all = FALSE)

# delete icuid
dfDevDel <- dfDev[, -1]

# regroup
dfDevDel$group <- ifelse(dfDevDel$group == 4, 1, 0)

# task definition
taskDev <- as_task_classif(dfDevDel, target = "devgcs", positive = "1")

# pipline building
po1Dev <-
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
taskDevPo1 <- po1Dev$train(taskDev)[[1]]
names(taskDevPo1$data())

# //ANCHOR - boruta

library(Boruta)

set.seed(0)

devPo1Boruta <- Boruta(devgcs ~ .,
    data = taskDevPo1$data(),
    maxRuns = 200
)
# devPo1Boruta

# devPo1Boruta$finalDecision

devNamesConf <- names(devPo1Boruta$finalDecision[devPo1Boruta$finalDecision == "Confirmed"])
print(devNamesConf)

devNamesTent <- names(devPo1Boruta$finalDecision[devPo1Boruta$finalDecision == "Tentative"])
print(devNamesTent)

devNames <- c(devNamesConf, devNamesTent)
print(devNames)

# Boruta::plotImpHistory(devPo1Boruta)

# plot(devPo1Boruta, xlab = "Attributes", ylab = "Importance:Z-Score", las = 2)

# //ANCHOR - reshape

# install.packages("devtools")
# devtools::install_github("Tong-Chen/ImageGP")

library(ImageGP)

# -------------------------------- plot start -------------------------------- #
boruta.variable.imp <- boruta.imp(devPo1Boruta)

sp_boxplot(boruta.variable.imp, melted=T, xvariable = "Variable", yvariable = "Importance",
           legend_variable = "finalDecision", legend_variable_order = c("shadowMax", "shadowMean", "shadowMin", "Confirmed"),
           xtics_angle = 90)
# --------------------------------- plot end --------------------------------- #

# //!SECTION

# //SECTION - shap

# //ANCHOR - preprocess

# task definition
taskDevSub <- taskDevPo1$select(devNames)

# pipeline building
po2Dev <-
    po(
        "classbalancing",
        reference = "major", adjust = "minor", shuffle = FALSE, ratio = 1
    )

# pipeline application
set.seed(0)

taskDevSubPo2 <- po2Dev$train(list(taskDevSub))[[1]]
names(taskDevSubPo2$data())

# //ANCHOR - afs

# split to train and external set
splitDev <- partition(taskDevSubPo2, ratio = 0.8)

# create auto fselector
afsDev <- auto_fselector(
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
afsDev$train(taskDevSubPo2, splitDev$train)

# predict with final model
afsDev$predict(taskDevSubPo2, splitDev$test)

# show result
print(afsDev$fselect_result$importance)

rfDev <- afsDev$learner

# //ANCHOR - visualization

taskDevSubAfs <- taskDevSubPo2$select(afsDev$fselect_result$feature[[1]])

dfShapDev <- taskDevSubAfs$data()

# shap
library(kernelshap)

shapKsDev <- kernelshap(rfDev, dfShapDev[1:300, -1], dfShapDev)

# viz
library(shapviz)

vizKsDev <- shapviz(shapKsDev, which_class = 1)

# -------------------------------- plot start -------------------------------- #
sv_importance(vizKsDev, kind = "beeswarm")

# dfShapDev[, ]
# sv_force(vizKsDev, row_id = 1) # ture negative
# dfShapDev[, ]
# sv_force(vizKsDev, row_id = 9) # ture positive
# --------------------------------- plot end --------------------------------- #

# interaction
library(vivid)

viDev <- vivi(data = dfShapDev, fit = rfDev, response = "devgcs")

# -------------------------------- plot start -------------------------------- #
# heatmap
viviHeatmap(
    viDev,
    intPal = rev(
        colorspace::sequential_hcl(palette = "Sunset", n = 100)
    ), # color of interaction
    impPal = rev(
        colorspace::sequential_hcl(palette = "RdPu", n = 100)
    ) # color of vars importance
)

# # network
# viviNetwork(
#     viDev,
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
dfCovDev <- dfDev[, c("icuid", "age", "gender", "bmi", devNamesConf)]

# regroup
dfCovDev$group <- ifelse(dfCovDev$group == 4, 1, 0)

# merge
dfCovDev <- merge(gcs[, c(1, 4)], dfCovDev, by = "icuid", all = FALSE)

# //!SECTION