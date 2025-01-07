# //SECTION - import

library(tidyverse)

# ---------------------------------------------------------------------------- #
#                             time interval: 5 mins                            #
# ---------------------------------------------------------------------------- #

# //ANCHOR - mimic

# icp
micp <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/micp.csv", header = TRUE)

names(micp)[1] <- c("icuid")

# bp
mbp <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/mbp.csv", header = TRUE)

names(mbp)[1] <- c("icuid")

mbp <- mbp[, c("icuid", "interval", "isbp", "idbp")]

# hr
mhr <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/mhr.csv", header = TRUE)

names(mhr)[1] <- c("icuid")

# //ANCHOR - eicu

# icp
eicp <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/eicp.csv", header = TRUE)

names(eicp)[1] <- c("icuid")

# bp
ebp <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/ebp.csv", header = TRUE)

names(ebp)[1] <- c("icuid")

ebp <- ebp[, c("icuid", "interval", "isbp", "idbp")]

# hr
ehr <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/ehr.csv", header = TRUE)

names(ehr)[1] <- c("icuid")

# //ANCHOR - combine

# combine
icp <- rbind(eicp, micp)
bp <- rbind(ebp, mbp)
hr <- rbind(ehr, mhr)

# merge
bpHr <- merge(bp, hr, by = c("icuid", "interval"), all = TRUE)
icpBpHr <- merge(icp, bpHr, by = c("icuid", "interval"), all.x = TRUE)

# //!SECTION

# //SECTION - preprocess

# //ANCHOR - denoise

icpBpHr0 <- icpBpHr

# denoise of icp
icpBpHr0$icp <-
    ifelse(icpBpHr0$icp >= 100, NA, icpBpHr0$icp)

# denoise of sbp
icpBpHr0$sbp <-
    ifelse(icpBpHr0$isbp < 30 | icpBpHr0$isbp > 300, NA, icpBpHr0$isbp)

# denoise of dbp
icpBpHr0$dbp <-
    ifelse(icpBpHr0$idbp < 10 | icpBpHr0$idbp > 200, NA, icpBpHr0$idbp)

# denoise of hr
icpBpHr0$hr <-
    ifelse(icpBpHr0$hr < 10, NA, icpBpHr0$dbp)

# summary
# hist(icpBp0$icp)
# qqnorm(icpBp0$icp)
# qqline(icpBp0$icp)

# hist(icpBp0$sbp)
# qqnorm(icpBp0$sbp)
# qqline(icpBp0$sbp)

# hist(icpBp0$dbp)
# qqnorm(icpBp0$dbp)
# qqline(icpBp0$dbp)

# hist(icpBp0$hr)
# qqnorm(icpBp0$hr)
# qqline(icpBp0$hr)

# //ANCHOR - derive

icpBpHr1 <- icpBpHr0

icpBpHr1$mab <- round(((icpBpHr1$sbp + 2 * icpBpHr1$dbp) / 3))
icpBpHr1$pp <- round((icpBpHr1$sbp - icpBpHr1$dbp))
icpBpHr1$cpp <- round((icpBpHr1$mab - icpBpHr1$icp))
icpBpHr1$rpp <- round(icpBpHr1$sbp * icpBpHr1$hr)

# //ANCHOR - fill

# filling the missing data with n/a
icpBpHr2 <- icpBpHr1[, c("icuid", "interval", "icp", "cpp", "rpp")] %>%
    complete(
        icuid,
        interval = seq(0, 1439),
        fill = list(
            icp = NA,
            cpp = NA,
            rpp = NA
        )
    )

# //!SECTION

# //SECTION - sample

# //ANCHOR - avg

library(tidyverse)

# avg of 4h
avg4H <- icpBpHr2 %>%
    mutate(interval = floor(interval / 48)) %>%
    group_by(icuid, interval) %>%
    summarize(
        avgicp = round(mean(icp, na.rm = TRUE), 2),
        avgcpp = round(mean(cpp, na.rm = TRUE), 2),
        avgrpp = round(mean(rpp, na.rm = TRUE), 2),
        .groups = "drop"
    )

# inclusion
avgDf <- avg4H %>%
    group_by(icuid) %>%
    filter(sum(is.na(avgicp)) <= 20) %>%
    filter(sum(is.na(avgcpp)) <= 20) %>%
    filter(sum(is.na(avgrpp)) <= 20) %>%
    as.data.frame()

colMeans(is.na(avgDf))

print(length(unique(avg4H$icuid)))
print(length(unique(avgDf$icuid)))

print(sum(unique(avg4H$icuid) %in% micp$icuid))
print(sum(unique(avg4H$icuid) %in% eicp$icuid))
print(sum(unique(avgDf$icuid) %in% micp$icuid))
print(sum(unique(avgDf$icuid) %in% eicp$icuid))

# //ANCHOR - imputation

library(missForest)

set.seed(0)

trajMf <- missForest(avgDf)

trajImp <- trajMf$ximp

# //!SECTION
