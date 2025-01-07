# //SECTION - boruta

library(mlr3verse)

library(tidyverse)

# //ANCHOR - preprocess

dfMor <- merge(varsImp, mortality, by = "icuid", all = FALSE)

# delete icuid
dfMorDel <- dfMor[, -1]

# regroup
dfMorDel$group <- ifelse(dfMorDel$group == 4, 1, 0)

# task definition
taskMor <- as_task_classif(dfMorDel, target = "hospMortality", positive = "1")

# pipline building
po1Mor <-
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
taskMorPo1 <- po1Mor$train(taskMor)[[1]]
names(taskMorPo1$data())

# //ANCHOR - boruta

library(Boruta)

set.seed(0)

morPo1Boruta <- Boruta(hospMortality ~ .,
    data = taskMorPo1$data(),
    maxRuns = 200
)
# morPo1Boruta

# morPo1Boruta$finalDecision

morNamesConf <- names(morPo1Boruta$finalDecision[morPo1Boruta$finalDecision == "Confirmed"])
print(morNamesConf)

morNamesTent <- names(morPo1Boruta$finalDecision[morPo1Boruta$finalDecision == "Tentative"])
print(morNamesTent)

morNames <- c(morNamesConf, morNamesTent)
print(morNames)

# Boruta::plotImpHistory(morPo1Boruta)

# plot(morPo1Boruta, xlab = "Attributes", ylab = "Importance:Z-Score", las = 2)

# //ANCHOR - reshape

# install.packages("devtools")
# devtools::install_github("Tong-Chen/ImageGP")

library(ImageGP)

boruta.imp <- function(x) {
    imp <- reshape2::melt(x$ImpHistory, na.rm = T)[, -1]
    colnames(imp) <- c("Variable", "Importance")
    imp <- imp[is.finite(imp$Importance), ]

    variableGrp <- data.frame(
        Variable = names(x$finalDecision),
        finalDecision = x$finalDecision
    )

    showGrp <- data.frame(
        Variable = c("shadowMax", "shadowMean", "shadowMin"),
        finalDecision = c("shadowMax", "shadowMean", "shadowMin")
    )

    variableGrp <- rbind(variableGrp, showGrp)

    boruta.variable.imp <- merge(imp, variableGrp, all.x = T)

    sortedVariable <- boruta.variable.imp %>%
        group_by(Variable) %>%
        summarise(median = median(Importance)) %>%
        arrange(median)
    sortedVariable <- as.vector(sortedVariable$Variable)


    boruta.variable.imp$Variable <- factor(boruta.variable.imp$Variable, levels = sortedVariable)

    invisible(boruta.variable.imp)
}

# -------------------------------- plot start -------------------------------- #
boruta.variable.imp <- boruta.imp(morPo1Boruta)

sp_boxplot(boruta.variable.imp, melted=T, xvariable = "Variable", yvariable = "Importance",
           legend_variable = "finalDecision", legend_variable_order = c("shadowMax", "shadowMean", "shadowMin", "Confirmed"),
           xtics_angle = 90)
# --------------------------------- plot end --------------------------------- #

# //!SECTION

# //SECTION - shap

# //ANCHOR - preprocess

# task definition
taskMorSub <- taskMorPo1$select(morNames)

# pipeline building
po2Mor <-
    po(
        "classbalancing",
        reference = "major", adjust = "minor", shuffle = FALSE, ratio = 1
    )

# pipeline application
set.seed(0)

taskMorSubPo2 <- po2Mor$train(list(taskMorSub))[[1]]
names(taskMorSubPo2$data())

# //ANCHOR - afs

# split to train and external set
splitMor <- partition(taskMorSubPo2, ratio = 0.8)

# create auto fselector
afsMor <- auto_fselector(
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
afsMor$train(taskMorSubPo2, splitMor$train)

# predict with final model
afsMor$predict(taskMorSubPo2, splitMor$test)

# show result
print(afsMor$fselect_result$importance)

rfMor <- afsMor$learner

# //ANCHOR - visualization

taskMorSubAfs <- taskMorSubPo2$select(afsMor$fselect_result$feature[[1]])

dfShapMor <- taskMorSubAfs$data()

# shap
library(kernelshap)

shapKsMor <- kernelshap(rfMor, dfShapMor[1:300, -1], dfShapMor)

# viz
library(shapviz)

vizKsMor <- shapviz(shapKsMor, which_class = 1)

# -------------------------------- plot start -------------------------------- #
sv_importance(vizKsMor, kind = "beeswarm")

# dfShapMor[, ]
# sv_force(vizKsMor, row_id = 1) # ture negative
# dfShapMor[, ]
# sv_force(vizKsMor, row_id = 9) # ture positive
# --------------------------------- plot end --------------------------------- #

# interaction
library(vivid)

viMor <- vivi(data = dfShapMor, fit = rfMor, response = "hospMortality")

# -------------------------------- plot start -------------------------------- #
# heatmap
viviHeatmap(
    viMor,
    intPal = rev(
        colorspace::sequential_hcl(palette = "Sunset", n = 100)
    ), # color of interaction
    impPal = rev(
        colorspace::sequential_hcl(palette = "RdPu", n = 100)
    ) # color of vars importance
)

# # network
# viviNetwork(
#     viMor,
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
dfCovMor <- dfMor[, c("icuid", "age", "gender", "bmi", morNamesConf)]

# regroup
dfCovMor$group <- ifelse(dfCovMor$group == 4, 1, 0)

# merge
dfCovMor <- merge(mortality, dfCovMor, by = "icuid", all = FALSE)

# //!SECTION