# //ANCHOR - preprocess

# including patient, score, diagnosis, surgery, group, day1vital
baselineGroup <- dfTraj[, c(1:27, 80:86)]
baselineGroup$race <- as.numeric(baselineGroup$race)

# //ANCHOR - group

library(compareGroups)

tableGroup <- descrTable(group ~ . - icuid,
    data = baselineGroup,
    method = NA,
    show.all = TRUE
)
# tableGroup

export2word(tableGroup, file = "tableGroup.docx")

# //ANCHOR - mortality

baselineMor <- merge(baselineGroup, mortality, by = "icuid", all = FALSE)

library(compareGroups)

tableMor <- descrTable(hospMortality ~ . - icuid,
    data = baselineMor,
    method = NA,
    show.all = TRUE
)
# tableMor

export2word(tableMor, file = "tableMor.docx")