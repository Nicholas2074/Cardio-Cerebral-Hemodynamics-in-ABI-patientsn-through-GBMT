```
# //ANCHOR - fliter

# exclude patients with recordings < 4800
library(dplyr)

icpBp2 <- icpBp2 %>%
  group_by(icuid) %>%
  filter(sum(is.na(cpp)) < 4800) %>%
  ungroup()

table(is.na(icpBp2$cpp)) # FALSE 46890 TRUE 8407
length(unique(icpBp2$icuid)) # 457
```

