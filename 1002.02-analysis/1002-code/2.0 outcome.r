# //ANCHOR - hospMortality

# eicu
emortality <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/emortality.csv", header = TRUE)

names(emortality) <- c("icuid", "hospMortality")

# mimic
mmortality <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/mmortality.csv", header = TRUE)

names(mmortality) <- c("icuid", "hospMortality")

# combine
mortality <- rbind(emortality, mmortality)

# filling
mortality$hospMortality[is.na(mortality$hospMortality)] <- 0

# //ANCHOR - gcs

# eicu
egcs <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/edev_gcs.csv", header = TRUE)

names(egcs) <- c("icuid", "admgcs", "disgcs", "devgcs")

# mimic
mgcs <- read.csv("C:/Users/zhouh/OneDrive/321-stat/1002.02/1002-oridata/mdev_gcs.csv", header = TRUE)

names(mgcs) <- c("icuid", "admgcs", "disgcs", "devgcs")

# combine
gcs <- rbind(egcs, mgcs)

# filling
# gcs$disgcs[is.na(gcs$disgcs)] <- 0
# # without missing data !!!

# gcs$devgcs[is.na(gcs$devgcs)] <- 0
# # without missing data !!!

# relabel
gcs$disgcs <- ifelse(gcs$disgcs <= 8, 1, 0)

gcs$devgcs <- ifelse(gcs$devgcs <= 0, 1, 0)

# //ANCHOR - link

# merge
trajMor <- merge(trajGroup, mortality, by = "icuid", all = FALSE)
trajDis <- merge(trajGroup, gcs[, c(1, 3)], by = "icuid", all = FALSE)
trajDev <- merge(trajGroup, gcs[, c(1, 4)], by = "icuid", all = FALSE)

print(length(unique(trajMor$icuid)))
print(length(unique(trajDev$icuid)))
print(length(unique(trajDev$icuid)))

save.image()
