# //SECTION - tuning

varsAvg <- c("avgicp", "avgcpp", "avgrpp")

# //ANCHOR - grid search

# parameter
paraGrid <- expand.grid(2:3, 2:6)
dim(paraGrid)
# [1] 10  2

# parallel computing
library(gbmt)

library(doParallel)

# clear env
# env <- foreach:::.foreachGlobals
# rm(list = ls(name = env), pos = env)

# cores
cores <- detectCores()
cl <- makeCluster(cores)
registerDoParallel(cl)

# 0 (no normalisation)
# 1 (centering)
# 2 (standardization)
# 3 (ratio to the mean) 
# 4 (logarithmic ratio to the mean)
# Default is 2 (standardization)

gbmtList <- list()

gbmtList <- foreach(i = 1:10, .packages = "gbmt") %dopar% {
    gbmt(
        x.names = varsAvg,
        unit = "icuid",
        time = "interval",
        d = paraGrid[i, 1],
        ng = paraGrid[i, 2],
        data = trajImp,
        scaling = 2,
        maxit = 200
    )
}

# stop
stopCluster(cl)

gbmtListInfo <- lapply(gbmtList, function(mod) {
    mod$ic
})

print(gbmtListInfo)

gbmtList[[9]] # model 9 is the best

print(paraGrid)

# //ANCHOR - modeling

library(gbmt)

# gbmt26 <- gbmt(
#     x.names = varsAvg,
#     unit = "icuid",
#     time = "interval",
#     d = 2,
#     ng = 6,
#     data = trajImp,
#     scaling = 2,
#     maxit = 200
# )

gbmt25 <- gbmt(
    x.names = varsAvg,
    unit = "icuid",
    time = "interval",
    d = 2,
    ng = 5,
    data = trajImp,
    scaling = 2,
    maxit = 200
)
gbmt25

# gbmt26 is the best
# gbmt25 is more simple

# traj group
trajGroup <- as.data.frame(unique(trajImp$icuid))
names(trajGroup) <- "icuid"

trajAssign <- gbmt25$assign.list

trajGroup$group[trajGroup$icuid %in% trajAssign[[1]]] <- 1
trajGroup$group[trajGroup$icuid %in% trajAssign[[2]]] <- 2
trajGroup$group[trajGroup$icuid %in% trajAssign[[3]]] <- 3
trajGroup$group[trajGroup$icuid %in% trajAssign[[4]]] <- 4
trajGroup$group[trajGroup$icuid %in% trajAssign[[5]]] <- 5
# trajGroup$group[trajGroup$icuid %in% trajAssign[[6]]] <- 6

trajGroup$group <- as.factor(trajGroup$group)

# //!SECTION

# //SECTION - plot

mar0 <- c(3.1, 2.55, 3.1, 1.2)

plot(gbmt25,
    n.ahead = 3,
    bands = FALSE,
    # conf = 0.95,
    # ylim = c(-0.1, 0.1),
    mar = mar0,
    equal.scale = TRUE
    # trim = 0.05
    # transparency = 95
)

# //!SECTION